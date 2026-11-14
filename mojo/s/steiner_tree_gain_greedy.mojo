# Clean-room bounded Steiner gain-greedy profile; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn st_find(parent: InlineArray[Int,4], vertex: Int) -> Int:
    var v=vertex
    while parent[v]!=v: v=parent[v]
    return v

fn st_join(mut parent: InlineArray[Int,4], u: Int, v: Int) -> Bool:
    let a=st_find(parent,u); let b=st_find(parent,v)
    if a==b: return False
    parent[b]=a
    return True

fn st_groups(n: Int, terminals: Int, edges: Int) -> Int:
    var parent=InlineArray[Int,4](0,1,2,3)
    for u in range(n):
        for v in range(u+1,n):
            if (edges & (1 << (4*u+v)))!=0: _=st_join(parent,u,v)
    var roots=InlineArray[Bool,4](fill=False)
    var result=0
    for v in range(n):
        if (terminals & (1 << v))!=0:
            let root=st_find(parent,v)
            if not roots[root]: roots[root]=True; result+=1
    return result

# Kruskal over the selected edges, sorted by weight and then endpoints.
fn st_forest(n: Int, weights: InlineArray[Int64,16], edges: Int,
             mut selected_u: InlineArray[Int,3], mut selected_v: InlineArray[Int,3],
             mut selected_count: Int) -> Int64:
    var parent=InlineArray[Int,4](0,1,2,3)
    var used=InlineArray[Bool,16](fill=False)
    var cost=Int64(0)
    selected_count=0
    for _ in range(6):
        var best = -1
        for u in range(n):
            for v in range(u+1,n):
                let id=4*u+v
                if (edges & (1 << id))==0 or used[id]: continue
                if best<0 or weights[id]<weights[best] or (weights[id]==weights[best] and id<best): best=id
        if best<0: break
        used[best]=True
        let u=best//4; let v=best%4
        if st_join(parent,u,v):
            selected_u[selected_count]=u; selected_v[selected_count]=v; selected_count+=1
            cost+=weights[best]
    return cost

fn st_contracted(n: Int, terminals: Int, weights: InlineArray[Int64,16], edges: Int) -> Int64:
    var parent=InlineArray[Int,4](0,1,2,3)
    var d=weights
    for u in range(n):
        for v in range(u+1,n):
            if (edges & (1 << (4*u+v)))!=0:
                d[4*u+v]=0; d[4*v+u]=0; _=st_join(parent,u,v)
    for k in range(n):
        for i in range(n):
            for j in range(n): d[4*i+j]=min(d[4*i+j],d[4*i+k]+d[4*k+j])
    var roots=InlineArray[Int,4](fill=0); var count=0
    for v in range(n):
        if (terminals & (1 << v))==0: continue
        let root=st_find(parent,v)
        var exists=False
        for i in range(count):
            if roots[i]==root: exists=True
        if not exists: roots[count]=root; count+=1
    if count<=1: return 0
    var between=InlineArray[Int64,16](fill=0)
    var group_edges=0
    for a in range(count):
        for b in range(a+1,count):
            var best=Int64(1000000)
            for u in range(n):
                if st_find(parent,u)!=roots[a]: continue
                for v in range(n):
                    if st_find(parent,v)==roots[b]: best=min(best,d[4*u+v])
            between[4*a+b]=best; between[4*b+a]=best
            group_edges |= 1 << (4*a+b)
    var us=InlineArray[Int,3](fill=0); var vs=InlineArray[Int,3](fill=0); var used=0
    return st_forest(count,between,group_edges,us,vs,used)

@export("steiner_tree_gain_greedy")
fn steiner_tree_gain_greedy(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>37: return -1
    let n0=input[0]; let mask0=input[1]; let count0=input[2]
    if n0<2 or n0>4 or mask0<=0 or (mask0 >> Int(n0))!=0 or count0<1 or count0>4: return -1
    let n=Int(n0); let terminals=Int(mask0); let count=Int(count0)
    var terminal_count=0
    for v in range(n):
        if (terminals & (1 << v))!=0: terminal_count+=1
    if terminal_count<2: return -1
    var weights=InlineArray[Int64,16](fill=0); var at=3
    for u in range(n):
        for v in range(u+1,n):
            if at>=Int(length) or input[at]<0 or input[at]>1000: return -1
            weights[4*u+v]=input[at]; weights[4*v+u]=input[at]; at+=1
    for i in range(n):
        for j in range(n):
            for k in range(n):
                if weights[4*i+j]>weights[4*i+k]+weights[4*k+j]: return -1
    var family=InlineArray[Int,4](fill=0); var family_union=0
    for c in range(count):
        if at>=Int(length): return -1
        let ec0=input[at]; at+=1
        if ec0<1 or ec0>=n0 or at+2*Int(ec0)>Int(length): return -1
        let ec=Int(ec0)
        var parent=InlineArray[Int,4](0,1,2,3); var degree=InlineArray[Int,4](fill=0)
        for _ in range(ec):
            let u0=input[at]; let v0=input[at+1]; at+=2
            if u0<0 or u0>=n0 or v0<0 or v0>=n0 or u0==v0: return -1
            let u=Int(u0); let v=Int(v0)
            if not st_join(parent,u,v): return -1
            let edge=1 << (4*min(u,v)+max(u,v))
            if (family[c] & edge)!=0: return -1
            family[c] |= edge; family_union |= edge
            degree[u]+=1; degree[v]+=1
        var vertices=0; var leaves=0; var root = -1
        for v in range(n):
            if degree[v]==0: continue
            vertices+=1
            let r=st_find(parent,v)
            if root<0: root=r
            elif root!=r: return -1
            if degree[v]==1:
                if (terminals & (1 << v))==0: return -1
                leaves+=1
            elif (terminals & (1 << v))!=0: return -1
        if vertices!=ec+1 or leaves<2 or leaves>3: return -1
    if at!=Int(length) or st_groups(n,terminals,family_union)!=1: return -1
    var terminal_edges=0
    for u in range(n):
        for v in range(u+1,n):
            if (terminals & (1 << u))!=0 and (terminals & (1 << v))!=0: terminal_edges |= 1 << (4*u+v)
    var us=InlineArray[Int,3](fill=0); var vs=InlineArray[Int,3](fill=0); var chosen_count=0
    let baseline=st_forest(n,weights,terminal_edges,us,vs,chosen_count)
    var selected=InlineArray[Bool,4](fill=False); var h=0
    while st_groups(n,terminals,h)>1:
        let before=st_groups(n,terminals,h)
        var best = -1; var best_gain=Int64(-1000000000)
        for c in range(count):
            if selected[c]: continue
            let trial=h | family[c]
            if st_groups(n,terminals,trial)>=before: continue
            let forest=st_forest(n,weights,trial,us,vs,chosen_count)
            let gain=baseline-st_contracted(n,terminals,weights,trial)-forest
            if best<0 or gain>best_gain: best=c; best_gain=gain
        if best<0: return -1
        selected[best]=True; h |= family[best]
    let cost=st_forest(n,weights,h,us,vs,chosen_count)
    let bytes=8*(3+2*chosen_count)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    var words=InlineArray[Int64,9](fill=0)
    words[0]=1; words[1]=cost; words[2]=Int64(chosen_count)
    for i in range(chosen_count): words[3+2*i]=Int64(us[i]); words[4+2*i]=Int64(vs[i])
    for i in range(3+2*chosen_count):
        let bits=bitcast[UInt64](words[i])
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(bytes)
