from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("gray_code")
fn gray_code(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>13:return -1
    let bits=Int(v[0]);let count=0 if bits==0 else 1<<bits;let bytes=count*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let value=UInt32(i^(i>>1))
        for b in range(4):out[4*i+b]=UInt8((value>>UInt32(8*b))&255)
    return Int64(count)
