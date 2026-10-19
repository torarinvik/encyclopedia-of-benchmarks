from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn jug_sqrt(n:Int64)->Int64:
    var lo:Int64=0;var hi=n+1
    while hi-lo>1:
        let mid=lo+(hi-lo)//2
        if mid<=n//mid:lo=mid
        else:hi=mid
    return lo
@export("juggler_sequence")
fn juggler_sequence(start:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if start<1 or start>25:return -1
    var a=InlineArray[Int64,16](fill=0);var count=1;a[0]=start
    while a[count-1]!=1:
        let x=a[count-1]
        a[count]=jug_sqrt(x) if x%2==0 else jug_sqrt(x*x*x)
        count+=1
    let bytes=count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let bits=UInt32(a[i])
        for b in range(4):o[4*i+b]=UInt8((bits>>UInt32(8*b))&255)
    return Int64(bytes)
