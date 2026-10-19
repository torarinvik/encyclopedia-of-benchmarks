from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("x932_padding")
fn x932_padding(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let block=v[0]
    if block<1 or block>64:return -1
    for i in range(1,Int(n)):if v[i]<0 or v[i]>255:return -1
    let payload=Int(n)-1;let pad=Int(block)-(payload%Int(block));let total=payload+pad
    if cap<c_size_t(total) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(payload):o[i]=UInt8(v[i+1])
    for i in range(payload,total-1):o[i]=0
    o[total-1]=UInt8(pad)
    return Int64(total)
