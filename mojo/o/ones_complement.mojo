from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("ones_complement")
fn ones_complement(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):if v[i]!=48 and v[i]!=49:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<n:return -2
    for i in range(Int(n)):o[i]=UInt8(if v[i]==48:49 else:48)
    return Int64(n)
