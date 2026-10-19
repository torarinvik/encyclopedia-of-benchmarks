from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("modpow")
fn modpow(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4 or n!=3:return -9223372036854775808
    var b=v[0];var e=v[1];let m=v[2]
    if b<0 or b>89000000 or e<0 or e>64 or m<1 or m>89000000:return -9223372036854775808
    if e==0:return -9223372036854775808 if b==0 else 1%m
    if b==0:return 0
    var res:Int64=1%m
    while e>0:
        if e%2==1:res=(res*b)%m;e-=1
        else:b=(b*b)%m;e/=2
    return res
