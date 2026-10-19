from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("non_preemptive_priority_scheduling")
fn non_preemptive_priority_scheduling(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>31:return -1
    let count=a[0]
    if count<1 or count>10 or n!=c_size_t(1+3*count):return -1
    var arrival=InlineArray[Int64,10]();var burst=InlineArray[Int64,10]();var priority=InlineArray[Int64,10]();var done=InlineArray[Bool,10](fill=False);var seen=InlineArray[Bool,11](fill=False)
    for i in range(Int(count)):
        let at=a[1+3*i];let bt=a[2+3*i];let pr=a[3+3*i]
        if at<0 or at>20 or bt<1 or bt>10 or pr<0 or pr>10 or seen[Int(pr)]:return -1
        arrival[i]=at;burst[i]=bt;priority[i]=pr;seen[Int(pr)]=True
    var staged=InlineArray[UInt8,40]();var time:Int64=0;var bytes=0
    for _ in range(Int(count)):
        var selected=-1
        for i in range(Int(count)):
            if not done[i] and arrival[i]<=time and (selected<0 or priority[i]<priority[selected]):selected=i
        if selected<0:
            var earliest:Int64=9223372036854775807
            for i in range(Int(count)):if not done[i] and arrival[i]<earliest:earliest=arrival[i]
            time=earliest
            for i in range(Int(count)):
                if not done[i] and arrival[i]<=time and (selected<0 or priority[i]<priority[selected]):selected=i
        let bits=bitcast[UInt32](Int32(selected))
        for b in range(4):staged[bytes]=UInt8((bits>>UInt(8*b))&255);bytes+=1
        done[selected]=True;time+=burst[selected]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
