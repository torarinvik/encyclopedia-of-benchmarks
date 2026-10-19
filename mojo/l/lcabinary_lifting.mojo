from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("lca_binary_lifting_benchmark")
fn lca_binary_lifting_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>771:return -1
    let nv=v[0];let root=v[1];let ec=v[2]
    if nv<2 or nv>128 or root<0 or root>=nv or ec!=nv-1:return -1
    if 3+2*Int(ec)+1>Int(n):return -1
    var adj=InlineArray[Int64,32768](fill=-1);var deg=InlineArray[Int64,128](fill=0);var dsu=InlineArray[Int64,128](fill=0)
    for i in range(Int(nv)):dsu[i]=Int64(i)
    var pos=3
    for _ in range(Int(ec)):
        let a=v[pos];let b=v[pos+1];pos+=2
        if a<0 or a>=nv or b<0 or b>=nv or a==b:return -1
        var ra=Int(a);while dsu[ra]!=ra:ra=Int(dsu[ra])
        var rb=Int(b);while dsu[rb]!=rb:rb=Int(dsu[rb])
        if ra==rb:return -1
        dsu[ra]=Int64(rb)
        adj[Int(a)*128+Int(deg[a])]=b;deg[a]+=1;adj[Int(b)*128+Int(deg[b])]=a;deg[b]+=1
    if pos>=Int(n):return -1
    let nq=v[pos];pos+=1
    if nq<0 or nq>256 or pos+2*Int(nq)!=Int(n):return -1
    var parent=InlineArray[Int64,128](fill=-1);var depth=InlineArray[Int64,128](fill=0);var q=InlineArray[Int64,128](fill=0)
    var h=0;var t=1;q[0]=root;parent[root]=root
    while h<t:
        let u=Int(q[h]);h+=1
        for j in range(Int(deg[u])):
            let w=Int(adj[u*128+j])
            if w==Int(parent[u]):continue
            if parent[w]>=0:return -1
            parent[w]=Int64(u);depth[w]=depth[u]+1;q[t]=Int64(w);t+=1
    if t!=Int(nv):return -1
    var up=InlineArray[Int64,896](fill=0)
    for i in range(Int(nv)):up[i*7]=parent[i]
    var levels=0
    while (1<<levels)<Int(nv):levels+=1
    for lev in range(1,levels):
        for i in range(Int(nv)):up[i*7+lev]=up[Int(up[i*7+lev-1])*7+lev-1]
    var checksum:Int64=0
    for qi in range(Int(nq)):
        var a=v[pos];var b=v[pos+1];pos+=2
        if a<0 or a>=nv or b<0 or b>=nv:return -1
        while depth[a]>depth[b]:a=up[Int(a)*7]
        while depth[b]>depth[a]:b=up[Int(b)*7]
        if a!=b:
            for levr in range(levels):
                let lev=levels-1-levr
                if up[Int(a)*7+lev]!=up[Int(b)*7+lev]:a=up[Int(a)*7+lev];b=up[Int(b)*7+lev]
            a=up[Int(a)*7]
        checksum+=Int64(qi+1)*(a+1)
    return checksum
