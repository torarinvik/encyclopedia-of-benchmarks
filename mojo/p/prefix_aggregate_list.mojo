from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("prefix_aggregate_list")
fn prefix_aggregate_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>260:return -1
    let init=v[0]
    if init<1 or init>64 or n<c_size_t(init+2):return -1
    var pref=InlineArray[Int64,128](fill=0)
    for i in range(Int(init)):
        if v[i+1]< -1000000 or v[i+1]>1000000:return -1
        pref[i]=v[i+1]+(pref[i-1] if i>0 else 0)
    let ops=v[Int(init)+1]
    if ops<0 or ops>64:return -1
    var live=Int(init);var cur=Int(init)+2;var qcount=0;var enc=InlineArray[UInt8,512](fill=0)
    for _ in range(Int(ops)):
        if cur>=Int(n):return -1
        let op=v[cur];cur+=1
        if op==0:
            if cur>=Int(n) or live>=128:return -1
            let x=v[cur];cur+=1
            if x< -1000000 or x>1000000:return -1
            pref[live]=pref[live-1]+x;live+=1
        elif op==1:
            if live<=1:return -1
            live-=1
        elif op==2:
            if cur+1>=Int(n):return -1
            let a=v[cur];let b=v[cur+1];cur+=2
            if a<1 or b<a or b>live:return -1
            let value=pref[Int(b)-1]-(pref[Int(a)-2] if a>1 else 0)
            let bits=UInt64(value)
            for i in range(8):enc[qcount*8+i]=UInt8((bits>>(8*i))&255)
            qcount+=1
        else:return -1
    if cur!=Int(n):return -1
    let bytes=qcount*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bytes):out[i]=enc[i]
    return Int64(bytes)
