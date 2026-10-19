from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shortest_seek_time_first")
fn shortest_seek_time_first(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let head=a[0];let count=a[1];if head<0 or head>255 or count<0 or count>64 or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]<0 or a[i+2]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    var used=InlineArray[Bool,64]();var cur=head
    for s in range(Int(count)):
        var best= -1;var dist=256
        for i in range(Int(count)):
            if not used[i]:let d=Int(abs(cur-a[i+2]));if d<dist:best=i;dist=d
        let x=a[best+2];o[s]=UInt8(x);used[best]=True;cur=x
    return count
