from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("lca")
fn lca(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>129:return -1
    let nv=v[0]
    if nv<1 or nv>64 or n!=c_size_t(2*nv+1):return -1
    var adj=InlineArray[Int64,4096](fill=-1);var deg=InlineArray[Int64,64](fill=0);var dsu=InlineArray[Int64,64](fill=0)
    for i in range(Int(nv)):dsu[i]=Int64(i)
    for e in range(Int(nv)-1):
        let a=v[1+2*e];let b=v[2+2*e]
        if a<0 or a>=nv or b<0 or b>=nv or a==b:return -1
        var ra=Int(a);while dsu[ra]!=ra:ra=Int(dsu[ra])
        var rb=Int(b);while dsu[rb]!=rb:rb=Int(dsu[rb])
        if ra==rb:return -1
        dsu[ra]=Int64(rb)
        adj[Int(a)*64+Int(deg[a])]=b;deg[a]+=1
        adj[Int(b)*64+Int(deg[b])]=a;deg[b]+=1
    let qa=v[2*Int(nv)-1];let qb=v[2*Int(nv)]
    if qa<0 or qa>=nv or qb<0 or qb>=nv:return -1
    var root=Int(dsu[0]);while dsu[root]!=root:root=Int(dsu[root])
    for i in range(1,Int(nv)):
        var r=Int(dsu[i]);while dsu[r]!=r:r=Int(dsu[r])
        if r!=root:return -1
    var parent=InlineArray[Int64,64](fill=-1);var depth=InlineArray[Int64,64](fill=0);var queue=InlineArray[Int64,64](fill=0)
    var head=0;var tail=1;queue[0]=0;parent[0]=0
    while head<tail:
        let u=Int(queue[head]);head+=1
        for j in range(Int(deg[u])):
            let w=Int(adj[u*64+j])
            if parent[w]<0:parent[w]=Int64(u);depth[w]=depth[u]+1;queue[tail]=Int64(w);tail+=1
    var a=Int(qa);var b=Int(qb)
    while depth[a]>depth[b]:a=Int(parent[a])
    while depth[b]>depth[a]:b=Int(parent[b])
    while a!=b:a=Int(parent[a]);b=Int(parent[b])
    return Int64(a)
