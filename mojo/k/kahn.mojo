from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kahn")
fn kahn(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -2
    let nv=a[0];let me=a[1]
    if nv<0 or nv>32 or me<0 or me>128 or n!=c_size_t(2+2*me):return -2
    var adj=InlineArray[Bool,1024](fill=false);var indeg=InlineArray[Int,32](fill=0)
    for i in range(Int(me)):
        let x=a[2+2*i];let y=a[3+2*i]
        if x<0 or y<0 or x>=nv or y>=nv:return -2
        let ix=Int(x)*32+Int(y)
        if not adj[ix]:adj[ix]=true;indeg[Int(y)]+=1
    var q=InlineArray[Int,32](fill=0);var head=0;var tail=0
    for i in range(Int(nv)):if indeg[i]==0:q[tail]=i;tail+=1
    var processed=0
    while head<tail:
        let x=q[head];head+=1;processed+=1
        for y in range(Int(nv)):if adj[x*32+y]:indeg[y]-=1;if indeg[y]==0:q[tail]=y;tail+=1
    return Int64(processed)
