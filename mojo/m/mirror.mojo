from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("mirror")
fn mirror(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<0 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0])
    for i in range(count):if v[i+1]<1 or v[i+1]>127:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count+1):return -2
    for i in range(count):out[i]=UInt8(v[count-i])
    out[count]=0
    return Int64(count)
