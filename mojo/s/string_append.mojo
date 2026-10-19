from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("string_append")
fn string_append(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let a=v[0]
    if a<0 or a>64 or 1+a>=Int64(n) or v[1+Int(a)]<0 or v[1+Int(a)]>64:return -1
    let b=v[1+Int(a)]
    if n!=c_size_t(2+a+b):return -1
    for i in range(Int(a+b)):
        if v[2+i]<32 or v[2+i]>126:return -1
    let size=Int(a+b)
    if cap<c_size_t(size) or (size>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(size):o[i]=UInt8(v[2+i])
    return Int64(size)
