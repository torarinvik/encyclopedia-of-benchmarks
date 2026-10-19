from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("length_of_list")
fn length_of_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]<0 or v[i]>100000:return -1
    return Int64(n)
