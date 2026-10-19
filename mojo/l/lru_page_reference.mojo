from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lrp_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("lru_page_reference")
fn lru_page_reference(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let capacity=v[0];let refs=v[1]
    if capacity<1 or capacity>64 or (capacity&(capacity-1))!=0 or refs<0 or refs>256 or n!=c_size_t(refs+2):return -1
    for i in range(Int(refs)):
        if v[i+2]<0 or v[i+2]>1000000:return -1
    var cache=InlineArray[Int64,64](fill=0);var events=InlineArray[Int64,512](fill=0);var used=0
    for i in range(Int(refs)):
        let page=v[i+2];var p=0
        while p<used and cache[p]!=page:p+=1
        if p<used:
            for j in range(p,0,-1):cache[j]=cache[j-1]
            cache[0]=page;events[2*i]=1;events[2*i+1]= -1
        else:
            var evicted:Int64= -1
            if used==Int(capacity):evicted=cache[used-1];used-=1
            for j in range(used,0,-1):cache[j]=cache[j-1]
            cache[0]=page;used+=1;events[2*i]=0;events[2*i+1]=evicted
    let words=2*Int(refs)+2+used;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[Int64,578](fill=0);var k=0;staged[k]=refs;k+=1
    for i in range(2*Int(refs)):staged[k]=events[i];k+=1
    staged[k]=Int64(used);k+=1
    for i in range(used):staged[k]=cache[i];k+=1
    for i in range(words):lrp_put(o,i*8,staged[i])
    return Int64(bytes)
