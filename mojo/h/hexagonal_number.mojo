from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hexagonal_number")
fn hexagonal_number(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<1 or a[0]>67108864:return -1
    return a[0]*(2*a[0]-1)
