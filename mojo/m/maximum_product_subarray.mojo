from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("maximum_product_subarray")
fn maximum_product_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>9:return -9223372036854775808
    for i in range(Int(n)):if v[i]< -10 or v[i]>10:return -9223372036854775808
    var cmax=v[0];var cmin=v[0];var best=v[0]
    for i in range(1,Int(n)):
        let x=v[i];let frommax=cmax*x;let frommin=cmin*x
        cmax=max(x,max(frommax,frommin));cmin=min(x,min(frommax,frommin));best=max(best,cmax)
    return best
