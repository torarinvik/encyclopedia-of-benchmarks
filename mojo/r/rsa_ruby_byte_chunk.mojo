from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn modpow_ruby(base:Int64,ex:Int64)->Int64:
    var result:Int64=1
    for _ in range(Int(ex)):result*=base
    return result%33
fn hash_byte_rb(mut h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*UInt64(1099511628211)
@export("cipher_then_decipher_byte_chunks")
fn cipher_then_decipher_byte_chunks(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>69:return -1
    let modulus=v[0];let e=v[1];let d=v[2];let count=v[3]
    if modulus!=33 or e<1 or e>7 or d<1 or d>7 or count<1 or count>64 or Int(n)!=4+Int(count):return -1
    for i in range(Int(count)):if v[4+i]<0 or v[4+i]>32:return -1
    var h=UInt64(14695981039346656037)
    for i in range(Int(count)):
        let c=modpow_ruby(v[4+i],e);h=hash_byte_rb(h,UInt8(48+c/10));h=hash_byte_rb(h,UInt8(48+c%10))
    for i in range(Int(count)):let c=modpow_ruby(v[4+i],e);h=hash_byte_rb(h,UInt8(modpow_ruby(c,d)))
    return Int64(h&UInt64(0x7fffffffffffffff))
