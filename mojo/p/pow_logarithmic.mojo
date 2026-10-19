from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pow_log(base:Int64,exp:Int64)->Int64:
    if exp==0:return 1
    let half=pow_log(base,exp//2);let square=half*half
    return if exp%2==0:square else:square*base
@export("pow_logarithmic")
fn pow_logarithmic(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<-10 or v[0]>10 or v[1]<0 or v[1]>15:return -9223372036854775808
    return pow_log(v[0],v[1])
