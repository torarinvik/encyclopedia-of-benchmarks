from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn dh_prime(n:Int64)->Bool:
    if n<2:return false
    var d:Int64=2
    while d<=n/d:
        if n%d==0:return false
        d+=1
    return true
fn dh_pow(base0:Int64,exp0:Int64,p:Int64)->Int64:
    var base=base0%p;var exp=exp0;var result:Int64=1%p
    while exp>0:
        if (exp&1)!=0:result=result*base%p
        base=base*base%p;exp>>=1
    return result
@export("diffie_hellman")
fn diffie_hellman(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1
    let g=input[0];let a=input[1];let b=input[2];let p=input[3]
    if p<2 or p>6700417 or not dh_prime(p) or g<1 or g>=p or a<1 or a>=p or b<1 or b>=p:return -1
    return dh_pow(dh_pow(g,a,p),b,p)
