from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("singly_link_list_deletion")
fn singly_link_list_deletion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>66:return -1
    let count=a[0];let pos=a[1];if count<1 or count>64 or n!=c_size_t(count+2) or pos<1 or pos>count:return -1
    for i in range(Int(count)):if a[i+2]<-2147483648 or a[i+2]>2147483647:return -1
    let bytes=Int(count-1)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var k=0
    for i in range(Int(count)):
        if i==Int(pos-1):continue
        let bits=UInt32(Int32(a[i+2]));for b in range(4):o[k*4+b]=UInt8((bits>>(8*b))&255)
        k+=1
    return bytes
