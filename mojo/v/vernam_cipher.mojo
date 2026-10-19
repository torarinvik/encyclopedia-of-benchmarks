from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("vernam_cipher")
fn vernam_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>2051:return -1
    let mode=v[0];let tl=v[1];let kl=v[2]
    if (mode!=0 and mode!=1) or tl<0 or tl>1024 or kl<1 or kl>1024 or n!=c_size_t(3+tl+kl):return -1
    for i in range(Int(tl)):
        if v[3+i]<65 or v[3+i]>90:return -1
    for i in range(Int(kl)):
        if v[3+Int(tl)+i]<65 or v[3+Int(tl)+i]>90:return -1
    if cap<c_size_t(tl) or (tl>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var buf=InlineArray[UInt8,1024](fill=0)
    for i in range(Int(tl)):
        let a=v[3+i]-65;let b=v[3+Int(tl)+i%Int(kl)]-65
        let x=if mode==0 then (a+b)%26 else (a-b+26)%26
        buf[i]=UInt8(65+x)
    for i in range(Int(tl)):o[i]=buf[i]
    return tl
