from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

comptime MAXN=256
comptime MAXQ=1024
comptime MAXA=510
comptime MAXQA=2048

fn tarjan_find(mut parent:InlineArray[Int64,MAXN],node:Int)->Int:
    var root=node
    while parent[root]!=Int64(root):root=Int(parent[root])
    var cur=node
    while parent[cur]!=Int64(cur):
        let nxt=Int(parent[cur]);parent[cur]=Int64(root);cur=nxt
    return root

fn tarjan_union(mut parent:InlineArray[Int64,MAXN],mut rank:InlineArray[Int64,MAXN],a:Int,b:Int):
    let ra=tarjan_find(parent,a);let rb=tarjan_find(parent,b)
    if ra==rb:return
    if rank[ra]<rank[rb]:parent[ra]=Int64(rb)
    elif rank[ra]>rank[rb]:parent[rb]=Int64(ra)
    else:parent[rb]=Int64(ra);rank[ra]+=1

@export("lowest_common_ancestor_tarjan")
fn lowest_common_ancestor_tarjan(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>4+2*(MAXN-1)+2*MAXQ:return -1
    let nn=v[0];let rootarg=v[1];let ee=v[2];let qq=v[3]
    if nn<1 or nn>MAXN or rootarg<0 or rootarg>=nn or ee!=nn-1 or qq<0 or qq>MAXQ:return -1
    let nodes=Int(nn);let edges=Int(ee);let queries=Int(qq);let qoff=4+2*edges
    if n!=c_size_t(qoff+2*queries):return -1
    var eh=InlineArray[Int64,MAXN](fill= -1);var eto=InlineArray[Int64,MAXA](fill=0);var enext=InlineArray[Int64,MAXA](fill=0);var arc=0
    for e in range(edges):
        let a=v[4+2*e];let b=v[5+2*e]
        if a<0 or a>=nn or b<0 or b>=nn or a==b:return -1
        eto[arc]=b;enext[arc]=eh[Int(a)];eh[Int(a)]=Int64(arc);arc+=1
        eto[arc]=a;enext[arc]=eh[Int(b)];eh[Int(b)]=Int64(arc);arc+=1
    var qh=InlineArray[Int64,MAXN](fill= -1);var qto=InlineArray[Int64,MAXQA](fill=0);var qnext=InlineArray[Int64,MAXQA](fill=0);var qid=InlineArray[Int64,MAXQA](fill=0)
    for qi in range(queries):
        let a=v[qoff+2*qi];let b=v[qoff+2*qi+1]
        if a<0 or a>=nn or b<0 or b>=nn:return -1
        let first=2*qi;let second=first+1
        qto[first]=b;qid[first]=Int64(qi);qnext[first]=qh[Int(a)];qh[Int(a)]=Int64(first)
        qto[second]=a;qid[second]=Int64(qi);qnext[second]=qh[Int(b)];qh[Int(b)]=Int64(second)
    # Validate connectivity before checking the output buffer.
    var seen=InlineArray[Int64,MAXN](fill=0);var stack=InlineArray[Int64,MAXN](fill=0);var top=1;var reached=0;stack[0]=rootarg;seen[Int(rootarg)]=1
    while top>0:
        top-=1;let node=Int(stack[top]);reached+=1;var edge=eh[node]
        while edge>=0:
            let child=Int(eto[Int(edge)])
            if seen[child]==0:seen[child]=1;stack[top]=Int64(child);top+=1
            edge=enext[Int(edge)]
    if reached!=nodes:return -1
    if cap<c_size_t(queries) or (queries>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var dsu=InlineArray[Int64,MAXN](fill=0);var rank=InlineArray[Int64,MAXN](fill=0);var ancestor=InlineArray[Int64,MAXN](fill=0)
    var done=InlineArray[Int64,MAXN](fill=0);var visited=InlineArray[Int64,MAXN](fill=0);var treeparent=InlineArray[Int64,MAXN](fill= -1);var cursor=InlineArray[Int64,MAXN](fill= -1);var dfs=InlineArray[Int64,MAXN](fill=0)
    for node in range(nodes):dsu[node]=Int64(node);ancestor[node]=Int64(node)
    let root=Int(rootarg);var depth=1;dfs[0]=rootarg;visited[root]=1;cursor[root]=eh[root]
    var answers=InlineArray[UInt8,MAXQ](fill=UInt8(0))
    while depth>0:
        let node=Int(dfs[depth-1]);let edge=cursor[node]
        if edge>=0:
            cursor[node]=enext[Int(edge)];let child=Int(eto[Int(edge)])
            if Int64(child)==treeparent[node]:continue
            if visited[child]!=0:return -1
            visited[child]=1;treeparent[child]=Int64(node);cursor[child]=eh[child];dfs[depth]=Int64(child);depth+=1
            continue
        done[node]=1;var item=qh[node]
        while item>=0:
            let other=Int(qto[Int(item)])
            if done[other]!=0:answers[Int(qid[Int(item)])]=UInt8(ancestor[tarjan_find(dsu,other)])
            item=qnext[Int(item)]
        depth-=1
        if treeparent[node]>=0:
            let par=Int(treeparent[node]);tarjan_union(dsu,rank,par,node);ancestor[tarjan_find(dsu,par)]=Int64(par)
    for qi in range(queries):out[qi]=answers[qi]
    return Int64(queries)
