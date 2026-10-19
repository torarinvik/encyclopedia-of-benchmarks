from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kahns_algorithm_long")
fn kahns_algorithm_long(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let nv=a[0];let me=a[1]
    if nv<1 or nv>32 or me<0 or me>128 or n!=c_size_t(2+2*me):return -1
    var from=InlineArray[Int,128](fill=0);var to=InlineArray[Int,128](fill=0);var indeg=InlineArray[Int,32](fill=0);var dist=InlineArray[Int,32](fill=1)
    for e in range(Int(me)):
        let x=a[2+2*e];let y=a[3+2*e]
        if x<0 or x>=nv or y<0 or y>=nv:return -1
        from[e]=Int(x);to[e]=Int(y);indeg[Int(y)]+=1
    var q=InlineArray[Int,32](fill=0);var head=0;var tail=0
    for i in range(Int(nv)):if indeg[i]==0:q[tail]=i;tail+=1
    var visited=0;var best=1
    while head<tail:
        let x=q[head];head+=1;visited+=1
        for e in range(Int(me)):
            if from[e]==x:
                let y=to[e];dist[y]=max(dist[y],dist[x]+1);best=max(best,dist[y]);indeg[y]-=1
                if indeg[y]==0:q[tail]=y;tail+=1
    if visited!=Int(nv):return -1
    return Int64(best)
