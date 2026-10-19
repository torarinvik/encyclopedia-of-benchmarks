from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("multiply_digit")
fn multiply_digit(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -9223372036854775808
    if v[0] < -1000000000 or v[0]>1000000000 or v[1] < -1000000000 or v[1]>1000000000:return -9223372036854775808
    return v[0]*v[1]
