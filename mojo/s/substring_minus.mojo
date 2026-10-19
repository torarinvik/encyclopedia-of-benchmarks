from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("substring_minus")
fn substring_minus(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>128:return -1
    let count=Int(n)-1
    for i in range(Int(n)):if v[i]<1 or v[i]>127:return -1
    var sum:Int64=0
    for i in range(count):sum+=Int64(i+1)*v[i]
    return Int64(count)*1100000+sum
