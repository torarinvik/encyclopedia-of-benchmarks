# Clean-room bounded fixed-embedding angle assignment; see RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn up_augment(term: Int, slots: InlineArray[Int,8], slot_count: Int,
               terminals: InlineArray[Int,8], incidence: InlineArray[Bool,96],
               mut owner: InlineArray[Int,8], mut seen: InlineArray[Bool,8]) -> Bool:
    for s in range(slot_count):
        if not incidence[12*terminals[term]+slots[s]] or seen[s]: continue
        seen[s]=True
        if owner[s]<0 or up_augment(owner[s],slots,slot_count,terminals,incidence,owner,seen):
            owner[s]=term
            return True
    return False

fn up_feasible(first: Int, count: Int, f: Int, cap: InlineArray[Int,12],
                terminals: InlineArray[Int,8], incidence: InlineArray[Bool,96]) -> Bool:
    var slots=InlineArray[Int,8](fill=0); var slot_count=0
    for face in range(f):
        for _ in range(cap[face]):
            if slot_count>=8: return False
            slots[slot_count]=face; slot_count+=1
    var owner=InlineArray[Int,8](fill=-1)
    for term in range(first,count):
        var seen=InlineArray[Bool,8](fill=False)
        if not up_augment(term,slots,slot_count,terminals,incidence,owner,seen): return False
    return True

@export("upward_planarity_angle_assignment")
fn upward_planarity_angle_assignment(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>124: return -1
    let n0=input[0]; let m0=input[1]; let f0=input[2]; let outer0=input[3]
    if n0<2 or n0>8 or m0<1 or m0>18 or f0<1 or f0>12 or outer0<0 or outer0>=f0: return -1
    let n=Int(n0); let m=Int(m0); let f=Int(f0); let outer=Int(outer0)
    if length!=c_size_t(4+6*m+f): return -1
    var eu=InlineArray[Int,18](fill=0); var ev=InlineArray[Int,18](fill=0)
    var adjacency=InlineArray[Bool,64](fill=False); var outgoing=InlineArray[Bool,64](fill=False)
    var indegree=InlineArray[Int,8](fill=0)
    for i in range(m):
        let u0=input[4+2*i]; let v0=input[5+2*i]
        if u0<0 or u0>=n0 or v0<0 or v0>=n0 or u0==v0: return -1
        let u=Int(u0); let v=Int(v0)
        if i>0 and (eu[i-1]>u or (eu[i-1]==u and ev[i-1]>=v)): return -1
        if adjacency[8*u+v]: return -1
        eu[i]=u; ev[i]=v; adjacency[8*u+v]=True; adjacency[8*v+u]=True
        outgoing[8*u+v]=True; indegree[v]+=1
    var walk_lengths=InlineArray[Int,12](fill=0)
    var walk_u=InlineArray[Int,36](fill=0); var walk_v=InlineArray[Int,36](fill=0)
    var darts=InlineArray[Bool,64](fill=False)
    var corner=InlineArray[Int,96](fill=-1); var incidence=InlineArray[Bool,96](fill=False)
    var successor=InlineArray[Int,64](fill=-1)
    var switches=InlineArray[Int,24](fill=0)
    var cursor=4+2*m; var total=0
    for face in range(f):
        if cursor>=Int(length): return -1
        let k0=input[cursor]; cursor+=1
        if k0<1 or k0>Int64(2*m) or total+Int(k0)>2*m: return -1
        let k=Int(k0); walk_lengths[face]=k
        if cursor+2*k>Int(length): return -1
        for _ in range(k):
            let u0=input[cursor]; let v0=input[cursor+1]; cursor+=2
            if u0<0 or u0>=n0 or v0<0 or v0>=n0: return -1
            let u=Int(u0); let v=Int(v0)
            if not adjacency[8*u+v] or darts[8*u+v]: return -1
            darts[8*u+v]=True; walk_u[total]=u; walk_v[total]=v; total+=1
    if cursor!=Int(length) or total!=2*m or n-m+f!=2: return -1
    for i in range(m):
        if not darts[8*eu[i]+ev[i]] or not darts[8*ev[i]+eu[i]]: return -1
    cursor=0
    for face in range(f):
        let k=walk_lengths[face]; let base=cursor
        for i in range(k):
            let u=walk_u[cursor]; let v=walk_v[cursor]; let next=base+(i+1)%k; let w=walk_v[next]
            if v!=walk_u[next] or successor[8*v+u]>=0: return -1
            successor[8*v+u]=w
            if corner[8*face+v]<0: corner[8*face+v]=i
            incidence[12*v+face]=True
            let x=outgoing[8*v+u]; let y=outgoing[8*v+w]
            if x and y: switches[2*face]+=1
            if not x and not y: switches[2*face+1]+=1
            cursor+=1
    var reached=InlineArray[Bool,8](fill=False); var queue=InlineArray[Int,8](fill=0)
    var head=0; var tail=1; reached[0]=True
    while head<tail:
        let u=queue[head]; head+=1
        for v in range(n):
            if adjacency[8*u+v] and not reached[v]: reached[v]=True; queue[tail]=v; tail+=1
    for v in range(n):
        if not reached[v]: return -1
    var degree=indegree
    head=0; tail=0
    for v in range(n):
        if degree[v]==0: queue[tail]=v; tail+=1
    var removed=0
    while head<tail:
        let u=queue[head]; head+=1; removed+=1
        for v in range(n):
            if outgoing[8*u+v]:
                degree[v]-=1
                if degree[v]==0: queue[tail]=v; tail+=1
    if removed!=n: return -1
    for v in range(n):
        var d=0; var start = -1
        for u in range(n):
            if adjacency[8*v+u]:
                d+=1
                if successor[8*v+u]<0: return -1
                start=u
        if d>0:
            var current=start; var count=0; var transitions=0
            while True:
                if current<0 or count>=d: return -1
                count+=1
                let next=successor[8*v+current]
                if next<0 or next>=n: return -1
                if outgoing[8*v+current]!=outgoing[8*v+next]: transitions+=1
                current=next
                if current==start: break
            if count!=d or (transitions!=0 and transitions!=2): return -1
    var caps=InlineArray[Int,12](fill=0); var cap_sum=0; var feasible=True
    for face in range(f):
        if switches[2*face]!=switches[2*face+1]: return -1
        caps[face]=switches[2*face]+(1 if face==outer else -1)
        if caps[face]<0: feasible=False
        cap_sum+=caps[face]
    var terminals=InlineArray[Int,8](fill=0); var terminal_count=0
    for v in range(n):
        var outgoing_count=0
        for u in range(n):
            if outgoing[8*v+u]: outgoing_count+=1
        if indegree[v]==0 or outgoing_count==0:
            terminals[terminal_count]=v; terminal_count+=1
    if cap_sum!=terminal_count: feasible=False
    let bytes=8*(2+3*terminal_count)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    var chosen=InlineArray[Int,8](fill=-1)
    if feasible:
        for t in range(terminal_count):
            var found=False
            for face in range(f):
                if not incidence[12*terminals[t]+face] or caps[face]<=0: continue
                caps[face]-=1
                if up_feasible(t+1,terminal_count,f,caps,terminals,incidence):
                    chosen[t]=face; found=True; break
                caps[face]+=1
            if not found: feasible=False; break
    var words=InlineArray[Int64,26](fill=-1)
    words[0]=1 if feasible else 0; words[1]=Int64(terminal_count)
    if feasible:
        for t in range(terminal_count):
            let face=chosen[t]
            words[2+3*t]=Int64(terminals[t]); words[3+3*t]=Int64(face)
            words[4+3*t]=Int64(corner[8*face+terminals[t]])
    for i in range(2+3*terminal_count):
        let bits=bitcast[UInt64](words[i])
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(bytes)
