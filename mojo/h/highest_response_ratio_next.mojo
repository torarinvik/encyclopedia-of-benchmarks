from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("highest_response_ratio_next")
fn highest_response_ratio_next(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let count=a[0];if count<1 or count>64 or n!=c_size_t(1+2*count):return -1
    var arrival=InlineArray[Int64,64](fill=0);var burst=InlineArray[Int64,64](fill=0);var done=InlineArray[Bool,64](fill=false);var result=InlineArray[Int64,64](fill=0)
    for i in range(Int(count)):
        arrival[i]=a[1+2*i];burst[i]=a[2+2*i]
        if arrival[i]<0 or arrival[i]>100000 or burst[i]<1 or burst[i]>1000:return -1
        for j in range(i):if arrival[j]==arrival[i]:return -1
    var time:Int64=0;var completed=0
    while completed<Int(count):
        var best=-1
        for i in range(Int(count)):
            if done[i] or arrival[i]>time:continue
            if best<0:best=i
            else:
                let wi=time-arrival[i];let wb=time-arrival[best]
                if (wi+burst[i])*burst[best]>(wb+burst[best])*burst[i]:best=i
        if best<0:
            var next:Int64=100001
            for i in range(Int(count)):if not done[i] and arrival[i]<next:next=arrival[i]
            time=next;continue
        time+=burst[best];done[best]=true;result[best]=time-arrival[best];completed+=1
    let bytes=Int(count)*8
    if cap<c_size_t(bytes) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(Int(count)):
        let u=bitcast[UInt64](result[i])
        for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return Int64(bytes)
