from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("int2_binary")
fn int2_binary(value:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if value<0 or value>4294967295:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<32:return -2
    let bits=UInt32(value);var mask:UInt32=0x80000000
    for i in range(32):
        if (bits&mask)!=0:output[i]=49
        else:output[i]=48
        mask>>=1
    return 32
