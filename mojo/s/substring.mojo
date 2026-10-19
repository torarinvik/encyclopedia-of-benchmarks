from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("substring")
fn substring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let textn=Int(n)-2;let start=v[0];let requested=v[1]
    if start<0 or start>textn or requested<0 or requested>64:return -1
    for i in range(textn):if v[2+i]<1 or v[2+i]>127:return -1
    let rem=textn-Int(start);var count=Int(requested)
    if count==0 and rem>0:count=1
    if count>rem:count=rem
    var checksum:Int64=0
    for i in range(count):checksum+=Int64(i+1)*v[Int(start)+2+i]
    return Int64(count)*300000+checksum
