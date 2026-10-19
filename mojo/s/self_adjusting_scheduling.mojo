from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("self_adjusting_scheduling")
fn self_adjusting_scheduling(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>18:return -1
    let tasks=a[0];let steps=a[1];if tasks<1 or tasks>16 or steps<0 or steps>64 or n!=c_size_t(tasks+2):return -1
    var priority=InlineArray[Int64,16]();var wait=InlineArray[Int64,16]();var schedule=InlineArray[UInt8,64]()
    for i in range(Int(tasks)):priority[i]=a[i+2];if priority[i]< -2147483648 or priority[i]>2147483647:return -1
    for s in range(Int(steps)):
        for i in range(Int(tasks)):for j in range(i+1,Int(tasks)):if priority[i]==priority[j]:return -1
        var best=0;for i in range(1,Int(tasks)):if priority[i]<priority[best]:best=i
        schedule[s]=UInt8(best);wait[best]+=1;priority[best]+=wait[best]
        if priority[best]< -2147483648 or priority[best]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(steps):return -2
    for i in range(Int(steps)):o[i]=schedule[i]
    return steps
