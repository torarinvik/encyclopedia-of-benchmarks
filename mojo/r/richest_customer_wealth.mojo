from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("richest_customer_wealth")
fn richest_customer_wealth(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1027 or v[0]<1 or v[0]>32 or v[1]<1 or v[1]>32:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if Int(n)!=2+rows*cols:return -1
    var richest:Int64=0
    for r in range(rows):
        var wealth:Int64=0
        for c in range(cols):let x=v[2+r*cols+c];if x<0 or x>1000000:return -1;wealth+=x
        if wealth>richest:richest=wealth
    return richest
