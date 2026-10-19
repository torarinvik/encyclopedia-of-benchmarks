from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("maximum_circular_subarray")
fn maximum_circular_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>64:return -9223372036854775808
    for i in range(Int(n)):if v[i]< -1000000 or v[i]>1000000:return -9223372036854775808
    var total=v[0];var curmax=v[0];var bestmax=v[0];var curmin=v[0];var bestmin=v[0]
    for i in range(1,Int(n)):
        let x=v[i];total+=x
        curmax=curmax+x if curmax+x>x else x;if curmax>bestmax:bestmax=curmax
        curmin=curmin+x if curmin+x<x else x;if curmin<bestmin:bestmin=curmin
    if bestmin==total:return bestmax
    return bestmax if bestmax>total-bestmin else total-bestmin
