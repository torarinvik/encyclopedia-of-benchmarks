from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn exponential_search_binary(values:UnsafePointer[Int64,ImmutAnyOrigin],low0:Int,high0:Int,target:Int64)->Int64:
    var low=low0;var high=high0
    while low<high:
        let mid=low+(high-low)//2;let value=values[mid]
        if value==target:return mid
        if value<target:low=mid+1
        else:high=mid
    return -1
@export("exponential_search")
fn exponential_search(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,target:Int64) abi("C")->Int64:
    if length==0:return -1
    var upper=1
    while upper<Int(length) and values[upper]<=target:
        upper=Int(length) if upper>Int(length)//2 else upper*2
    return exponential_search_binary(values,upper//2,upper,target)
