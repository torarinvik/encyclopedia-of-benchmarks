from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("maximum_twin_sum_of_linked_list")
fn maximum_twin_sum_of_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1024 or n%2!=0:return -1
    for i in range(Int(n)):if v[i]<1 or v[i]>100000:return -1
    var best:Int64=0
    for i in range(Int(n)/2):
        let total=v[i]+v[Int(n)-i-1];if total>best:best=total
    return best
