from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("theoretical_rot13")
fn theoretical_rot13(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>66 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if a[i]<1 or a[i]>127:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let x=a[i];let y=Int(x)
        o[i]=UInt8(if x>=97 and x<=122 else y)
        if x>=97 and x<=122:o[i]=UInt8(97+(y-97+13)%26)
    return Int64(n)
