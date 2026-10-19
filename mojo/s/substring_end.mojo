from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("substring_end")
fn substring_end(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let textn=Int(n)-1;let start=v[0]
    if start<0 or start>textn:return -1
    for i in range(textn):if v[i+1]<1 or v[i+1]>127:return -1
    let count=textn-Int(start);var sum:Int64=0
    for i in range(count):sum+=Int64(i+1)*v[Int(start)+i+1]
    return Int64(count)*1100000+sum
