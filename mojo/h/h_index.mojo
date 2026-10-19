from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("h_index")
fn h_index(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>5000 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var high=Int(length);var low=0
    for i in range(Int(length)):if values[i]<0 or values[i]>1000:return -1
    while low<high:
        let mid=(low+high+1)//2;var count=0
        for i in range(Int(length)):if values[i]>=mid:count+=1
        if count>=mid:low=mid
        else:high=mid-1
    return low
