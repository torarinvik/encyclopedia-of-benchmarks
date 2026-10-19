from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("xor_cipher")
fn xor_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>66:return -1
    let m=v[0];let k=v[1]
    if m<0 or m>63 or k<1 or k>63 or n!=c_size_t(2+m+k):return -1
    for i in range(Int(m+k)):if v[2+i]<0 or v[2+i]>255:return -1
    if cap<c_size_t(m) or (m>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(m)):o[i]=UInt8(v[2+i]^v[2+Int(m)+i%Int(k)])
    return m
