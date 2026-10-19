from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("inversions")
fn inversions(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>1024 or (length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        if values[i]< -2147483648 or values[i]>2147483647:return -1
    var count:Int64=0
    for i in range(Int(length)):
        for j in range(i+1,Int(length)):
            if values[i]>values[j]:count+=1
    return count
