from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("multiplexer")
fn multiplexer(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    if (v[0]!=0 and v[0]!=1) or (v[1]!=0 and v[1]!=1) or (v[2]!=0 and v[2]!=1):return -1
    return v[1] if v[2]==1 else v[0]
