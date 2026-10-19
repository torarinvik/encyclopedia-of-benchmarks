from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("maximum_subarray")
fn maximum_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1024:return -1
    for i in range(Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    var current=v[0];var best=current
    for i in range(1,Int(n)):
        current=current+v[i] if current>0 else v[i]
        if current>best:best=current
    return best
