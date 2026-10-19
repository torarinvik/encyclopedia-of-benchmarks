from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("swap_case")
fn swap_case(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    if n>cap or (n>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        var x=v[i]
        if x>=65 and x<=90:x+=32
        elif x>=97 and x<=122:x-=32
        out[i]=UInt8(x)
    return n
