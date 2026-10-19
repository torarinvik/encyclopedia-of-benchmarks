from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64rrb(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("round_robin")
fn round_robin(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>33 or v[0]<0 or v[0]>32 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var remaining=InlineArray[Int64,32](fill=0);var waiting=InlineArray[Int64,32](fill=0)
    for i in range(count):if v[i+1]<0 or v[i+1]>4096:return -1;remaining[i]=v[i+1]
    let bytes=8*(1+2*count);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var elapsed:Int64=0
    while True:
        var done=True
        for i in range(count):
            if remaining[i]>0:
                done=False
                if remaining[i]>2:elapsed+=2;remaining[i]-=2
                else:elapsed+=remaining[i];waiting[i]=elapsed-v[i+1];remaining[i]=0
        if done:break
    wr64rrb(o,0,Int64(count))
    for i in range(count):wr64rrb(o,8*(1+i),waiting[i])
    for i in range(count):wr64rrb(o,8*(1+count+i),v[i+1]+waiting[i])
    return Int64(bytes)
