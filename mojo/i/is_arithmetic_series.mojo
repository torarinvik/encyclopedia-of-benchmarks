from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_arithmetic_series")
fn is_arithmetic_series(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>64:return -1
    for i in range(Int(length)):
        if values[i]< -1000000 or values[i]>1000000:return -1
    if length==1:return 1
    let d=values[1]-values[0]
    for i in range(1,Int(length)-1):
        if values[i+1]-values[i]!=d:return 0
    return 1
