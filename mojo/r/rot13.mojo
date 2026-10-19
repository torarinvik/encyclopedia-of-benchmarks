from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("rot13")
fn rot13(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>66 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<1 or v[i]>127:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let x=Int(v[i]);var y=x
        if x>=65 and x<=90:y=65+(x-65+13)%26
        elif x>=97 and x<=122:y=97+(x-97+13)%26
        o[i]=UInt8(y)
    return Int64(n)
