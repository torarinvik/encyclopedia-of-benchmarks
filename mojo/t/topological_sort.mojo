from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("topological_sort")
fn topological_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or (n-1)%2!=0 or a[0]<0 or a[0]>64:return -2
    let nv=Int(a[0]);let edges=(Int(n)-1)/2;var adj=InlineArray[UInt64,64]();var deg=InlineArray[Int,64]()
    for e in range(edges):
        let u=a[1+2*e];let v=a[2+2*e]
        if u<0 or v<0 or u>=nv or v>=nv:return -2
        let mask=UInt64(1)<<UInt64(v)
        if (adj[Int(u)]&mask)==0:adj[Int(u)]=adj[Int(u)]|mask;deg[Int(v)]+=1
    var queue=InlineArray[Int,64]();var order=InlineArray[Int,64]();var head=0;var tail=0;var count=0
    for i in range(nv):
        if deg[i]==0:queue[tail]=i;tail+=1
    while head<tail:
        let u=queue[head];head+=1;order[count]=u;count+=1
        for v in range(nv):
            if (adj[u]&(UInt64(1)<<UInt64(v)))!=0:
                deg[v]-=1
                if deg[v]==0:queue[tail]=v;tail+=1
    if count!=nv:return -1
    if cap<c_size_t(nv) or (nv>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(nv):o[i]=UInt8(order[i])
    return Int64(count)
