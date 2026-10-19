from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("how_many_times_rotated")
fn how_many_times_rotated(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if a[i]< -2147483648 or a[i]>2147483647:return -1
    if n==0:return 0
    var lo=0;var hi=Int(n)-1
    while lo<hi:
        let mid=(lo+hi)//2
        if a[mid]>a[hi]:lo=mid+1
        else:hi=mid
    return Int64(lo)
