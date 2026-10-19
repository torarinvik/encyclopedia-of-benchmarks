from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("single_number")
fn single_number(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -2147483649
    var acc:Int64=0
    for i in range(Int(n)):
        if a[i]<-2147483648 or a[i]>2147483647:return -2147483649
        acc=acc ^ a[i]
    let bits=acc & 0xffffffff
    return bits-4294967296 if bits>=2147483648 else bits
