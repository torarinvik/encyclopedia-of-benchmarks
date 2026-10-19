from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn low32(x:UInt64)->UInt32:
    return UInt32(x & UInt64(0xffffffff))
@export("xtea")
fn xtea(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=25:return -1
    if v[0]<1 or v[0]>64:return -1
    for i in range(1,25):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    var v0:UInt32=0;var v1:UInt32=0;var key=InlineArray[UInt32,4](fill=0)
    for i in range(4):
        v0=(v0<<8)|UInt32(v[1+i]);v1=(v1<<8)|UInt32(v[5+i])
        for j in range(4):key[i]=(key[i]<<8)|UInt32(v[9+i*4+j])
    var sum:UInt32=0
    for _ in range(Int(v[0])):
        let mix=low32(UInt64((v1<<4)^(v1>>5))+UInt64(v1))
        let key_mix=low32(UInt64(sum)+UInt64(key[Int(sum&3)]))
        v0=low32(UInt64(v0)+UInt64(mix^key_mix))
        sum=low32(UInt64(sum)+UInt64(0x9e3779b9))
        let mix2=low32(UInt64((v0<<4)^(v0>>5))+UInt64(v0))
        let key_mix2=low32(UInt64(sum)+UInt64(key[Int((sum>>11)&3)]))
        v1=low32(UInt64(v1)+UInt64(mix2^key_mix2))
    for i in range(4):o[i]=UInt8((v0>>(24-8*i))&255);o[4+i]=UInt8((v1>>(24-8*i))&255)
    return 8
