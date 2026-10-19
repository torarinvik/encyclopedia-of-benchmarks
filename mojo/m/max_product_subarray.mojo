from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_product_subarray")
fn max_product_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>9 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -9223372036854775808
    if n==0:return 0
    var max_now=v[0];var min_now=v[0];var best=v[0]
    if v[0]< -10 or v[0]>10:return -9223372036854775808
    for i in range(1,Int(n)):
        let x=v[i];if x< -10 or x>10:return -9223372036854775808
        if x<0:let temp=max_now;max_now=min_now;min_now=temp
        let p1=max_now*x;max_now=x if x>p1 else p1
        let p2=min_now*x;min_now=x if x<p2 else p2
        if max_now>best:best=max_now
    return best
