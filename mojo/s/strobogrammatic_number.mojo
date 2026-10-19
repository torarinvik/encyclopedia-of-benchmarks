from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn rotate_digit(x:Int64)->Int64:
    if x==48:return 48
    if x==49:return 49
    if x==54:return 57
    if x==56:return 56
    if x==57:return 54
    return -1
@export("strobogrammatic_number")
fn strobogrammatic_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var l=0;var r=Int(n)
    while l<r:r-=1;if rotate_digit(v[l])!=v[r]:return 0;l+=1
    return 1
