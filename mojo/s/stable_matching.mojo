from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stable_matching")
fn stable_matching(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let nv=v[0]
    if nv<0 or nv>8:return -1
    let count=Int(nv);let square=count*count
    if n!=c_size_t(1+2*square):return -1
    var mp=InlineArray[Int64,64](fill=0);var wr=InlineArray[Int64,64](fill=0)
    for row in range(2*count):
        var seen=InlineArray[Bool,8](fill=False);let start=if row<count then 1+row*count else 1+square+(row-count)*count
        for rank in range(count):
            let manw=v[start+rank]
            if manw<0 or manw>=nv or seen[Int(manw)]:return -1
            seen[Int(manw)]=True
            if row<count:mp[row*count+rank]=manw
            else:wr[(row-count)*count+Int(manw)]=rank
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(16*count):return -2
    var woman=InlineArray[Int64,8](fill= -1);var man=InlineArray[Int64,8](fill= -1);var next=InlineArray[Int,8](fill=0);var queue=InlineArray[Int,8](fill=0)
    for i in range(count):queue[i]=i
    var head=0;var tail=0;var qc=count
    while qc>0:
        let m=queue[head];head=(head+1)%count;qc-=1;let rank=next[m];next[m]+=1;let w=Int(mp[m*count+rank]);let inc=woman[w]
        if inc<0:woman[w]=m;man[m]=w
        elif wr[w*count+m]<wr[w*count+Int(inc)]:
            woman[w]=m;man[m]=w;man[Int(inc)]= -1;queue[tail]=Int(inc);tail=(tail+1)%count;qc+=1
        else:queue[tail]=m;tail=(tail+1)%count;qc+=1
    var staged=InlineArray[Int64,16](fill=0)
    for i in range(count):staged[2*i]=i;staged[2*i+1]=man[i]
    for i in range(2*count):let bits=bitcast[UInt64](staged[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(16*count)
