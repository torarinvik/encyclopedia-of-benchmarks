from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("reverse_complement")
fn reverse_complement(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>1000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):let x=v[i];if x!=65 and x!=67 and x!=71 and x!=84:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let x=v[Int(n)-1-i]
        if x==65:o[i]=84
        elif x==84:o[i]=65
        elif x==67:o[i]=71
        else:o[i]=67
    return Int64(n)
