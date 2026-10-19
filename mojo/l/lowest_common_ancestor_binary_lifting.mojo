from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

comptime MAXN=256
comptime MAXQ=1024
comptime LEVELS=9

@export("lowest_common_ancestor_binary_lifting")
fn lowest_common_ancestor_binary_lifting(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>4+2*(MAXN-1)+2*MAXQ:return -1
    let nn=v[0];let rootarg=v[1];let ee=v[2];let qq=v[3]
    if nn<1 or nn>MAXN or rootarg<0 or rootarg>=nn or ee!=nn-1 or qq<0 or qq>MAXQ:return -1
    let nodes=Int(nn);let edges=Int(ee);let queries=Int(qq);let qoff=4+2*edges
    if n!=c_size_t(qoff+2*queries):return -1
    var head=InlineArray[Int64,MAXN](fill= -1);var to=InlineArray[Int64,510](fill=0);var next=InlineArray[Int64,510](fill=0);var arc=0
    for e in range(edges):
        let a=v[4+2*e];let b=v[5+2*e]
        if a<0 or a>=nn or b<0 or b>=nn or a==b:return -1
        to[arc]=b;next[arc]=head[Int(a)];head[Int(a)]=Int64(arc);arc+=1
        to[arc]=a;next[arc]=head[Int(b)];head[Int(b)]=Int64(arc);arc+=1
    for qi in range(queries):
        let a=v[qoff+2*qi];let b=v[qoff+2*qi+1]
        if a<0 or a>=nn or b<0 or b>=nn:return -1
    var parent=InlineArray[Int64,MAXN](fill= -2);var depth=InlineArray[Int64,MAXN](fill=0);var up=InlineArray[Int64,MAXN*LEVELS](fill=0);var stack=InlineArray[Int64,MAXN](fill=0)
    let root=Int(rootarg);parent[root]= -1;up[root]=Int64(root);var top=1;stack[0]=rootarg;var reached=0
    while top>0:
        top-=1;let node=Int(stack[top]);reached+=1;var edge=head[node]
        while edge>=0:
            let nb=Int(to[Int(edge)])
            if Int64(nb)!=parent[node]:
                if parent[nb]!= -2:return -1
                parent[nb]=Int64(node);depth[nb]=depth[node]+1;up[nb]=Int64(node);stack[top]=Int64(nb);top+=1
            edge=next[Int(edge)]
    if reached!=nodes:return -1
    if cap<c_size_t(queries) or (queries>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for level in range(1,LEVELS):
        for node in range(nodes):
            let halfway=Int(up[(level-1)*MAXN+node])
            up[level*MAXN+node]=up[(level-1)*MAXN+halfway]
    var answers=InlineArray[UInt8,MAXQ](fill=UInt8(0))
    for qi in range(queries):
        var a=Int(v[qoff+2*qi]);var b=Int(v[qoff+2*qi+1])
        if depth[a]<depth[b]:let tmp=a;a=b;b=tmp
        var diff=Int(depth[a]-depth[b])
        for level in range(LEVELS):
            if (diff & (1<<level))!=0:a=Int(up[level*MAXN+a])
        if a!=b:
            for rev in range(LEVELS):
                let level=LEVELS-1-rev
                if up[level*MAXN+a]!=up[level*MAXN+b]:a=Int(up[level*MAXN+a]);b=Int(up[level*MAXN+b])
            a=Int(up[a])
        answers[qi]=UInt8(a)
    for qi in range(queries):out[qi]=answers[qi]
    return Int64(queries)
