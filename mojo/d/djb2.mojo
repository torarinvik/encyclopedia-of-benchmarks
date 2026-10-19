from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("djb2")
fn djb2(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>65 or (length>0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()) or length>64:return -1
    var hash:UInt32=5381
    for i in range(Int(length)):
        let c=input[i]
        if c<0 or c>255:return -1
        hash=UInt32((UInt64(hash)*33+UInt64(c))&4294967295)
    return Int64(hash)
