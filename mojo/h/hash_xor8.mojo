from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hash_xor8")
fn hash_xor8(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100001 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var total:Int64=0
    for i in range(Int(n)):
        let b=a[i]
        if b==0:break
        if b<0 or b>127:return -1
        total=(total+b)&255
    return (-total)&255
