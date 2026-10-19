from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("long_utils")
fn long_utils(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or v[0]<0 or v[0]>3 or v[2]<0 or v[2]>63:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let bits=UInt64(v[1]);let d=Int(v[2]);var rotated=bits
    if d!=0:
        if v[0]<2:rotated=(bits<<d)|(bits>>(64-d))
        else:rotated=(bits>>d)|(bits<<(64-d))
    for i in range(8):out[i]=UInt8((rotated>>(8*i))&255)
    return 8
