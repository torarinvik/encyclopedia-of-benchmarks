from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("to_lower_case")
fn to_lower_case(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if a[i]<1 or a[i]>127:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let x=a[i];o[i]=UInt8(x+32 if x>=65 and x<=90 else x)
    return Int64(n)
