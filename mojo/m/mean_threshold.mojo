from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("mean_threshold")
fn mean_threshold(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1027 or v[0]<1 or v[0]>32 or v[1]<1 or v[1]>32:return -1
    let width=Int(v[0]);let height=Int(v[1]);let count=width*height
    if n!=c_size_t(2+count):return -1
    var sum:Int64=0
    for i in range(count):
        if v[i+2]<0 or v[i+2]>255:return -1
        sum+=v[i+2]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    let mean=sum/Int64(count);var staged=InlineArray[UInt8,1024](fill=0)
    for i in range(count):staged[i]=255 if v[i+2]>mean else 0
    for i in range(count):out[i]=staged[i]
    return Int64(count)
