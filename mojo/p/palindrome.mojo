from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindrome")
fn palindrome(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    for i in range(Int(n/2)):if v[i]!=v[Int(n)-1-i]:return 0
    return 1
