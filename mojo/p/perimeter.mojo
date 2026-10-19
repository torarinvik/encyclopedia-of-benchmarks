from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("perimeter")
fn perimeter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<3 or v[0]>256 or v[1]<1 or v[1]>255:return -1
    return v[0]*v[1]
