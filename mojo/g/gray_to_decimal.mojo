from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("gray_to_decimal")
fn gray_to_decimal(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>64:return -1
    let bits=Int(v[0]);if bits<1 or bits>63 or n!=c_size_t(bits+1):return -1
    var prefix:Int64=0;var binary:Int64=0
    for i in range(1,Int(n)):
        if v[i]!=48 and v[i]!=49:return -1
        prefix^=v[i]-48;binary=binary*2+prefix
    return binary
