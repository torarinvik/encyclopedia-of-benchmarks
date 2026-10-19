from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("porta_cipher")
fn porta_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1091:return -1
    let mode=v[0];let tl=v[1];let kl=v[2]
    if (mode!=0 and mode!=1) or tl<0 or tl>1024 or kl<0 or kl>64 or n!=c_size_t(3+tl+kl) or (tl!=0 and kl==0):return -1
    for i in range(Int(tl)):
        let x=v[3+i];if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
    for i in range(Int(kl)):
        let x=v[3+Int(tl)+i];if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
    if cap<c_size_t(tl) or (tl>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(tl)):
        var letter=v[3+i];var key=v[3+Int(tl)+i%Int(kl)]
        if letter>=97:letter-=32
        if key>=97:key-=32
        let ix=letter-65;let group=(key-65)//2
        let mapped=if ix<13:13+(ix+13-group)%13 else:(ix-13+group)%13
        out[i]=UInt8(65+mapped)
    return tl
