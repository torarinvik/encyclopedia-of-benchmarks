from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("weighted_interval_scheduling")
fn weighted_interval_scheduling(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>193:return -1
    let count=a[0]
    if count<0 or count>64 or n!=c_size_t(1+3*count):return -1
    for i in range(Int(count)):
        let s=a[1+3*i];let e=a[2+3*i];let w=a[3+3*i]
        if s< -100000 or s>100000 or e< -100000 or e>100000 or s>=e or w<0 or w>1000000:return -1
    var order=InlineArray[Int32,64]();var pred=InlineArray[Int32,64]();var dp=InlineArray[Int64,65]();var selected=InlineArray[Int32,64]()
    for i in range(Int(count)):order[i]=Int32(i)
    for i in range(1,Int(count)):
        let key=order[i];var j=i
        while j>0 and a[2+3*Int(order[j-1])]>a[2+3*Int(key)]:order[j]=order[j-1];j-=1
        order[j]=key
    for j in range(Int(count)):
        var lo=0;var hi=Int(count)
        while lo<hi:
            let mid=lo+(hi-lo)/2
            if a[2+3*Int(order[mid])]<=a[1+3*Int(order[j])]:lo=mid+1
            else:hi=mid
        pred[j]=Int32(lo)
        let include=a[3+3*Int(order[j])]+dp[lo]
        dp[j+1]=include if include>dp[j] else dp[j]
    var sc=0;var current=Int(count)
    while current>0:
        let j=current-1;let include=a[3+3*Int(order[j])]+dp[Int(pred[j])]
        if include>dp[current-1]:selected[sc]=order[j];sc+=1;current=Int(pred[j])
        else:current-=1
    for i in range(sc/2):let t=selected[i];selected[i]=selected[sc-1-i];selected[sc-1-i]=t
    let needed=16+4*sc
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    let wb=bitcast[UInt64](dp[Int(count)]);let cb=bitcast[UInt64](Int64(sc))
    for b in range(8):o[b]=UInt8((wb>>UInt(8*b))&255);o[8+b]=UInt8((cb>>UInt(8*b))&255)
    for i in range(sc):
        let bits=bitcast[UInt32](selected[i]);for b in range(4):o[16+i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(needed)
