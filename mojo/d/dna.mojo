from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("dna")
fn dna(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>1001 or values[0]!=0:return -1
    let n=Int(length)-1
    for i in range(n):
        let c=values[i+1]
        if c!=65 and c!=84 and c!=67 and c!=71:return -1
    if capacity<c_size_t(n) or (n>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(n):
        let c=values[i+1]
        if c==65:out[i]=84
        elif c==84:out[i]=65
        elif c==67:out[i]=71
        else:out[i]=67
    return Int64(n)
