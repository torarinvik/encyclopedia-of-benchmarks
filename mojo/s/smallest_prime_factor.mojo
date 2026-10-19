from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("smallest_prime_factor")
fn smallest_prime_factor(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<2 or a[0]>1000005:return -1
    let x=a[0];var d:Int64=2
    while d*d<=x:
        if x%d==0:return d
        d+=1
    return x
