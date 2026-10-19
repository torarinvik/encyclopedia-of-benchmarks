from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("modular_exponentiation")
fn modular_exponentiation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let raw=v[0];var e=v[1];let m=v[2]
    if raw < -2147483648 or raw>2147483647 or e<0 or e>2147483647 or m<1 or m>2147483647:return -1
    var b=raw%m;if b<0:b+=m
    var res:Int64=1%m
    while e>0:
        if e&1!=0:res=(res*b)%m
        b=(b*b)%m;e>>=1
    return res
