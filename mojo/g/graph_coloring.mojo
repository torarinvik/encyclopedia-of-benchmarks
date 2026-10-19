from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gc_count(masks:InlineArray[Int,8],colors:InlineArray[Int,8],n:Int,m:Int,vertex:Int)->Int64:
    if vertex==n:return 1
    var total:Int64=0
    for color in range(m):
        var safe=True
        for prior in range(vertex):
            if (masks[vertex]&(1<<prior))!=0 and colors[prior]==color:safe=False;break
        if safe:
            var next=colors;next[vertex]=color;total+=gc_count(masks,next,n,m,vertex+1)
    return total
@export("graph_coloring")
fn graph_coloring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>11 or v[0]<1 or v[0]>8 or v[1]<1 or v[1]>4:return -1
    let count=Int(v[0]);let m=Int(v[1]);if n!=c_size_t(count+2):return -1
    var masks=InlineArray[Int,8](fill=0);let limit=1<<count
    for i in range(count):
        if v[2+i]<0 or v[2+i]>=limit:return -1
        masks[i]=Int(v[2+i]);if (masks[i]&(1<<i))!=0:return -1
    for i in range(count):
        for j in range(count):if ((masks[i]>>j)&1)!=((masks[j]>>i)&1):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let colors=InlineArray[Int,8](fill=0);let value=UInt64(gc_count(masks,colors,count,m,0))
    for b in range(8):out[b]=UInt8((value>>UInt64(8*b))&255)
    return 8
