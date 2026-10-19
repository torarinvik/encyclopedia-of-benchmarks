from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn md_prime(n:Int64)->Bool:
    if n<2:return False
    var d:Int64=2
    while d<=n/d:
        if n%d==0:return False
        d+=1
    return True
fn md_pow(mut b:Int64,mut e:Int64,m:Int64)->Int64:
    var r:Int64=1;b%=m
    while e>0:
        if e&1!=0:r=(r*b)%m
        e>>=1;b=(b*b)%m
    return r
@export("modular_division")
fn modular_division(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let a=v[0];let b=v[1];let m=v[2]
    if a<0 or a>1000000000000 or b<0 or b>1000000000000 or m<2 or m>1000000 or not md_prime(m) or b%m==0:return -1
    return ((a%m)*md_pow(b,m-2,m))%m
