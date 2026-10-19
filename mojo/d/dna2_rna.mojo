from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("dna2_rna")
fn dna2_rna(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>1001 or values[0]!=0:return -1
    let n=Int(length)-1
    for i in range(n):if values[i+1]<65 or values[i+1]>90:return -1
    if capacity<c_size_t(n) or (n>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(n):out[i]=UInt8(85 if values[i+1]==84 else values[i+1])
    return Int64(n)
