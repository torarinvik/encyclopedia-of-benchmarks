from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("modulo")
fn modulo(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>5 or n!=2:return -1
    if v[0]<0 or v[0]>4294967295 or v[1]<1 or v[1]>4294967295:return -1
    return v[0]%v[1]
