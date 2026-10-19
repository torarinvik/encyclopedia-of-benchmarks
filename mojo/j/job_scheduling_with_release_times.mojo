from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("job_scheduling_with_release_times")
fn job_scheduling_with_release_times(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>193 or v[0]<0 or v[0]>64 or n!=c_size_t(1+3*v[0]):return -1
    let count=Int(v[0]);var ar=InlineArray[Int64,64](fill=0);var dl=InlineArray[Int64,64](fill=0);var pr=InlineArray[Int64,64](fill=0);var order=InlineArray[Int,64](fill=0);var maxd=0
    for i in range(count):
        ar[i]=v[1+3*i];dl[i]=v[2+3*i];pr[i]=v[3+3*i]
        if ar[i]<1 or ar[i]>64 or dl[i]<1 or dl[i]>64 or pr[i]<0 or pr[i]>1000000:return -1
        if dl[i]>maxd:maxd=Int(dl[i])
        order[i]=i
    for i in range(1,count):
        let key=order[i];var j=i
        while j>0 and pr[order[j-1]]<pr[key]:order[j]=order[j-1];j-=1
        order[j]=key
    var slots=InlineArray[Bool,65](fill=False);var num:Int64=0;var total:Int64=0
    for oi in range(count):
        let i=order[oi]
        if ar[i]<=dl[i]:
            var s=Int(dl[i]) if dl[i]<maxd else maxd
            while s>=ar[i]:
                if not slots[s]:slots[s]=True;num+=1;total+=pr[i];break
                s-=1
    return num*64000001+total
