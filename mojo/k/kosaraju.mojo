from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime V=40
fn kos_dfs(adj:InlineArray[Bool,1600],n:Int,v:Int,mut seen:InlineArray[Bool,40],mut order:InlineArray[Int64,40],mut used:Int):
    seen[v]=True
    for j in range(n):if adj[v*n+j] and not seen[j]:kos_dfs(adj,n,j,seen,order,used)
    order[used]=v;used+=1
fn kos_assign(adj:InlineArray[Bool,1600],n:Int,v:Int,mut label:InlineArray[Int64,40],c:Int):
    label[v]=c
    for j in range(n):if adj[j*n+v] and label[j]<0:kos_assign(adj,n,j,label,c)
@export("kosaraju")
fn kosaraju(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4096:return -1
    let nv=a[0];let ne=a[1]
    if nv<0 or nv>40 or ne<0 or ne>2047 or n!=c_size_t(2+2*ne):return -1
    var adj=InlineArray[Bool,1600]()
    for e in range(Int(ne)):
        let u=a[2+2*e];let v=a[3+2*e]
        if u<0 or u>=nv or v<0 or v>=nv:return -1
        adj[Int(u*nv+v)]=True
    var seen=InlineArray[Bool,40]();var order=InlineArray[Int64,40]();var used=0
    for i in range(Int(nv)):if not seen[i]:kos_dfs(adj,Int(nv),i,seen,order,used)
    var labels=InlineArray[Int64,40]();for i in range(40):labels[i]=-1
    var comps=0
    for r in range(Int(nv)):
        let v=Int(order[Int(nv)-1-r])
        if labels[v]<0:kos_assign(adj,Int(nv),v,labels,comps);comps+=1
    let required=1+Int(nv)+comps
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var pos=0;o[pos]=UInt8(comps);pos+=1
    for minv in range(Int(nv)):
        let c=Int(labels[minv]);var earlier=False
        for j in range(minv):if labels[j]==c:earlier=True
        if not earlier:
            var size=0
            for j in range(Int(nv)):if labels[j]==c:size+=1
            o[pos]=UInt8(size);pos+=1
            for j in range(Int(nv)):if labels[j]==c:o[pos]=UInt8(j);pos+=1
    return pos
