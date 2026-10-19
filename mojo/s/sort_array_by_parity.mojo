from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("sort_array_by_parity")
fn sort_array_by_parity(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>5000 or (length>0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):if input[i]<0 or input[i]>5000:return -1
    let bytes=length*4
    if capacity<bytes or (bytes>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var even=0;var odd=Int(length)
    for i in range(Int(length)):
        let value=UInt32(input[i]);var destination=0
        if (value&1)==0:destination=even;even+=1
        else:odd-=1;destination=odd
        for b in range(4):output[destination*4+b]=UInt8((value>>UInt(8*b))&255)
    return Int64(length)
