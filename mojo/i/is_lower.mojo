from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_lower")
fn is_lower(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        if input[i]<32 or input[i]>126:return -1
        if input[i]>=65 and input[i]<=90:return 0
    return 1
