from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hash_sdbm")
fn hash_sdbm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    var h:UInt64=0
    for i in range(Int(n)):
        if a[i]<1 or a[i]>127:return -1
        let b=UInt64(a[i]);h=b+(h<<6)+(h<<16)-h
    return bitcast[Int64](h)
