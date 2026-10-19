from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_sorted_array")
fn is_sorted_array(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>100000 or (length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        if values[i]< -9007199254740991 or values[i]>9007199254740991:return -1
    for i in range(0,Int(length)-1):
        if values[i]>=values[i+1]:return 0
    return 1
