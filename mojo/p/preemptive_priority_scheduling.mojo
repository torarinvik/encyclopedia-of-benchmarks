from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("preemptive_priority_scheduling")
fn preemptive_priority_scheduling(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<1 or n>33:return -1
    let count=v[0]
    if count<0 or count>8 or n!=c_size_t(1+4*count):return -1
    var ids=InlineArray[Int32,8](fill=0);var arr=InlineArray[Int32,8](fill=0);var rem=InlineArray[Int32,8](fill=0);var pri=InlineArray[Int32,8](fill=0);var seen=InlineArray[Bool,8](fill=False)
    for i in range(Int(count)):
        let id=v[1+4*i];let at=v[2+4*i];let burst=v[3+4*i];let p=v[4+4*i]
        if id<0 or id>=8 or seen[Int(id)] or at<0 or at>16 or burst<1 or burst>8:return -1
        for j in range(i):if pri[j]==p and arr[j]==at:return -1
        seen[Int(id)]=True;ids[i]=id;arr[i]=at;rem[i]=burst;pri[i]=p
    var seq=InlineArray[Int32,80](fill=0);var ticks=0;var done=0
    while done<Int(count):
        var best=Int(count)
        for i in range(Int(count)):
            if rem[i]<=0 or arr[i]>Int32(ticks):continue
            if best==Int(count) or pri[i]>pri[best] or (pri[i]==pri[best] and arr[i]<arr[best]):best=i
        if best==Int(count):seq[ticks]= -1
        else:
            seq[ticks]=ids[best];rem[best]-=1
            if rem[best]==0:done+=1
        ticks+=1
    let bytes=(ticks+1)*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var words=InlineArray[Int32,81](fill=0);words[0]=Int32(ticks)
    for i in range(ticks):words[i+1]=seq[i]
    for i in range(ticks+1):
        let bits=UInt32(words[i])
        for b in range(4):out[i*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
