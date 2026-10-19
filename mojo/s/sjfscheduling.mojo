from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sjfscheduling")
fn sjfscheduling(a:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int32,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(1+2*count):return -1
    var arrivals=InlineArray[Int32,64]();var bursts=InlineArray[Int32,64]();var done=InlineArray[Bool,64]();var order=InlineArray[Int32,64]()
    for i in range(Int(count)):
        arrivals[i]=a[1+2*i];bursts[i]=a[2+2*i]
        if arrivals[i]<0 or arrivals[i]>255 or bursts[i]<1 or bursts[i]>255:return -1
    var time:Int32=0;var scheduled=0
    while scheduled<Int(count):
        var best=Int(count)
        for i in range(Int(count)):
            if done[i] or arrivals[i]>time:continue
            if best==Int(count) or bursts[i]<bursts[best] or (bursts[i]==bursts[best] and (arrivals[i]<arrivals[best] or (arrivals[i]==arrivals[best] and i<best))):best=i
        if best==Int(count):time+=1
        else:order[scheduled]=Int32(best);scheduled+=1;done[best]=True;time+=bursts[best]
    let need=Int(count)*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    for i in range(Int(count)):
        let bits=UInt32(order[i]);for b in range(4):o[i*4+b]=UInt8((bits>>(8*b))&255)
    return need
