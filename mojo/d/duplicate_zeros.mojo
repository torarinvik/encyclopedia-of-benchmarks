from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn duplicate_zero_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt32(value)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("duplicate_zeros")
fn duplicate_zeros(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>64:return -1
    for i in range(Int(length)):
        if values[i]<0 or values[i]>1000:return -1
    let n=Int(length);let bytes=4*n
    if capacity<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var src=0;var dst=0
    while dst<n:
        let value=values[src];src+=1;duplicate_zero_put(out,dst*4,value);dst+=1
        if value==0 and dst<n:duplicate_zero_put(out,dst*4,0);dst+=1
    return Int64(n)
