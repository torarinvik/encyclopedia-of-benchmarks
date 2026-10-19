from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("maximum_subarray_allow_empty")
fn maximum_subarray_allow_empty(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    var current:Int64=0;var best:Int64=0
    for i in range(Int(n)):
        current+=v[i];if current<0:current=0;if current>best:best=current
    return best
