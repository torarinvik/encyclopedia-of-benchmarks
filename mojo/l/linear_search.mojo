from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_search")
fn linear_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,target:Int64) abi("C")->Int64:
    for i in range(Int(n)):
        if v[i]==target:return Int64(i)
    return -1
