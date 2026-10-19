from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tea_enc(block:UInt64,k0:UInt64,k1:UInt64)->UInt64:
    var v0=UInt64(UInt32(block&0xffffffff));var v1=UInt64(UInt32(block>>32));let a=UInt64(UInt32(k0&0xffffffff));let b=UInt64(UInt32(k0>>32));let c=UInt64(UInt32(k1&0xffffffff));let d=UInt64(UInt32(k1>>32));var sum:UInt64=0
    for _ in range(32):
        sum=(sum+0x9e3779b9)&0xffffffff
        v0=(v0+((((v1<<4)+a)&0xffffffff) ^ ((v1+sum)&0xffffffff) ^ (((v1>>5)+b)&0xffffffff)))&0xffffffff
        v1=(v1+((((v0<<4)+c)&0xffffffff) ^ ((v0+sum)&0xffffffff) ^ (((v0>>5)+d)&0xffffffff)))&0xffffffff
    return (v1<<32)|v0
fn tea_dec(block:UInt64,k0:UInt64,k1:UInt64)->UInt64:
    var v0=UInt64(UInt32(block&0xffffffff));var v1=UInt64(UInt32(block>>32));let a=UInt64(UInt32(k0&0xffffffff));let b=UInt64(UInt32(k0>>32));let c=UInt64(UInt32(k1&0xffffffff));let d=UInt64(UInt32(k1>>32));var sum:UInt64=0xc6ef3720
    for _ in range(32):
        v1=(v1-((((v0<<4)+c)&0xffffffff) ^ ((v0+sum)&0xffffffff) ^ (((v0>>5)+d)&0xffffffff)))&0xffffffff
        v0=(v0-((((v1<<4)+a)&0xffffffff) ^ ((v1+sum)&0xffffffff) ^ (((v1>>5)+b)&0xffffffff)))&0xffffffff
        sum=(sum-0x9e3779b9)&0xffffffff
    return (v1<<32)|v0
@export("tea")
fn tea(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>7 or n!=6:return -1
    for i in range(6):if a[i]< -2147483648 or a[i]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    var w=InlineArray[UInt64,6]()
    for i in range(6):w[i]=UInt64(bitcast[UInt32](Int32(a[i])))
    let block=(w[1]<<32)|w[0];let key0=(w[3]<<32)|w[2];let key1=(w[5]<<32)|w[4];let c=tea_enc(block,key0,key1);let r=tea_dec(c,key0,key1)
    for i in range(8):o[i]=UInt8((c>>UInt(8*i))&255);o[8+i]=UInt8((r>>UInt(8*i))&255)
    return 16
