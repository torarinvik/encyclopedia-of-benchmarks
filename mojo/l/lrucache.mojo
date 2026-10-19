from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lrc_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("lrucache")
fn lrucache(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>99:return -1
    let capacity=v[0];let ops=v[1]
    if capacity<2 or capacity>16 or ops<0 or ops>32 or n!=c_size_t(2+3*ops):return -1
    var keys=InlineArray[Int64,16](fill=0);var vals=InlineArray[Int64,16](fill=0);var used=0
    var seen=InlineArray[Int64,32](fill=0);var seen_n=0;var records=InlineArray[Int64,96](fill=0)
    for i in range(Int(ops)):
        let p=2+3*i;let op=v[p];let key=v[p+1];let value=v[p+2]
        if op<0 or op>1 or key<0 or key>1000000:return -1
        var pos=0
        while pos<used and keys[pos]!=key:pos+=1
        var returned:Int64= -1;var evicted:Int64= -1
        if op==0:
            if value<0 or value>1000000:return -1
            for j in range(seen_n):if seen[j]==key:return -1
            seen[seen_n]=key;seen_n+=1
            if used==Int(capacity):
                evicted=keys[0]
                for j in range(used-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
                used-=1
            keys[used]=key;vals[used]=value;used+=1
        else:
            if value!=0 or pos==used:return -1
            returned=vals[pos]
            for j in range(pos,used-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
            keys[used-1]=key;vals[used-1]=returned
        records[3*i]=op;records[3*i+1]=returned;records[3*i+2]=evicted
    var staged=InlineArray[Int64,130](fill=0);var words=0;staged[words]=ops;words+=1
    for i in range(3*Int(ops)):staged[words]=records[i];words+=1
    staged[words]=Int64(used);words+=1
    for j in range(used):let ix=used-1-j;staged[words]=keys[ix];staged[words+1]=vals[ix];words+=2
    let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(words):lrc_put(o,i*8,staged[i])
    return Int64(bytes)
