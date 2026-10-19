from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn powmod_hash(base:Int64,ex:Int64,m:Int64)->Int64:
    var power=base%m;var e=ex;var result:Int64=1
    while e>0:
        if e&1!=0:result=(result*power)%m
        power=(power*power)%m;e/=2
    return result
fn hash_u32_r(mut h:UInt64,x:Int64)->UInt64:
    let bits=UInt32(x)
    for j in range(4):h=(h^UInt64((bits>>(8*j))&UInt32(255)))*UInt64(1099511628211)
    return h
fn rsa_hash_transform(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t)->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>69:return -1
    let m=v[0];let e=v[1];let d=v[2];let count=v[3]
    if m<128 or m>55295 or e<1 or e>1000000 or d<1 or d>1000000 or count<1 or count>64 or Int(n)!=4+Int(count):return -1
    for i in range(Int(count)):if v[4+i]<0 or v[4+i]>127 or v[4+i]>=m:return -1
    var h=UInt64(14695981039346656037)
    for i in range(Int(count)):h=hash_u32_r(h,powmod_hash(v[4+i],e,m))
    for i in range(Int(count)):
        let c=powmod_hash(v[4+i],e,m);h=hash_u32_r(h,powmod_hash(c,d,m))
    return Int64(h&UInt64(0x7fffffffffffffff))
@export("encrypt_decrypt_big_integer_values")
fn encrypt_decrypt_big_integer_values(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    return rsa_hash_transform(v,n)
