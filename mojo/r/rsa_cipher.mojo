from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn powmodr(base:Int64,ex:Int64,m:Int64)->Int64:
    var b=base%m;var e=ex;var result:Int64=1
    while e>0:if e%2==1:result=(result*b)%m;e/=2;b=(b*b)%m
    return result
@export("rsa_cipher_encrypt_ascii")
fn rsa_cipher_encrypt_ascii(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let a=v[0];let e=v[1];let m=v[2]
    if a<0 or a>127 or m<128 or m>65535 or e<1 or e>=m:return -1
    return powmodr(a,e,m)
