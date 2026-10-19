from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_sorted")
fn is_sorted(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        if values[i]< -2147483648 or values[i]>2147483647:return -1
    for i in range(1,Int(length)):
        if values[i]<values[i-1]:return 0
    return 1
