from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("mul_array")
fn mul_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>9:return -1
    if n==0:return 1
    if v==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    var product:Int64=1
    for i in range(Int(n)):if v[i]<0 or v[i]>99:return -1;product*=v[i]
    return product
