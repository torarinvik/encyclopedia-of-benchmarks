from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hexadecimal_to_decimal")
fn hexadecimal_to_decimal(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>16:return -1
    var v:UInt64=0
    for i in range(Int(n)):
        let d=a[i]
        if d<0 or d>15 or v>(0x7fffffffffffffff-UInt64(d))//16:return -1
        v=v*16+UInt64(d)
    return Int64(v)
