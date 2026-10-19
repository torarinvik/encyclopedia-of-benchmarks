from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("divisors")
fn divisors(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or values[0]<1 or values[0]>62:return -1
    let n=values[0];var mask:UInt64=0
    for d in range(1,Int(n)+1):if n%Int64(d)==0:mask|=UInt64(1)<<UInt(d)
    return Int64(mask)
