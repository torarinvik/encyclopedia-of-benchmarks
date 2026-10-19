from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is")
fn is(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1:return -1
    return 1 if input[0]>=0 and input[0]<9007199254740992 else 0
