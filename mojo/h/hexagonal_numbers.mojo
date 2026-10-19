from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("hexagonal_numbers")
fn hexagonal_numbers(n:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n<1 or n>1024:return -1
    let bytes=Int(n)*8
    if cap<c_size_t(bytes) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(Int(n)):
        let v=Int64(i)*(2*Int64(i)-1);let u=bitcast[UInt64](v)
        for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return Int64(bytes)
