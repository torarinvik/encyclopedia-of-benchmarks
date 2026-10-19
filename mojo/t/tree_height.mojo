from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tree_height")
fn tree_height(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or a[0]<1 or a[0]>1023:return -1
    let count=Int(a[0]);if n!=c_size_t(1+2*(count-1)):return -1
    var adj=InlineArray[Bool,1048576]()
    for e in range(count-1):
        let u=a[1+2*e];let v=a[2+2*e]
        if u<1 or u>count or v<1 or v>count or u==v:return -1
        adj[Int(u)*1024+Int(v)]=True;adj[Int(v)*1024+Int(u)]=True
    var queue=InlineArray[Int,1023]();var depth=InlineArray[Int,1024]();var seen=InlineArray[Bool,1024]();var head=0;var tail=0;var maxdepth=1
    queue[tail]=1;tail+=1;seen[1]=True;depth[1]=1
    while head<tail:
        let u=queue[head];head+=1
        for v in range(1,count+1):
            if adj[u*1024+v] and not seen[v]:seen[v]=True;depth[v]=depth[u]+1;maxdepth=max(maxdepth,depth[v]);queue[tail]=v;tail+=1
    if tail!=count:return -1
    return Int64(maxdepth)
