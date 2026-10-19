from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("job_sequencing")
fn job_sequencing(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>98 or v[0]<1 or v[0]>32:return -1
    let count=Int(v[0]);if n!=c_size_t(1+3*count):return -1
    var seen=InlineArray[Bool,128](fill=False);var prev:Int64=1000001
    for i in range(count):
        let id=v[1+3*i];let d=v[2+3*i];let p=v[3+3*i]
        if not ((id>=65 and id<=90) or (id>=97 and id<=122)) or seen[Int(id)] or d<1 or d>count or p<1 or p>1000000 or p>=prev:return -1
        seen[Int(id)]=True;prev=p
    var slots=InlineArray[Int,32](fill=0);var total:Int64=0
    for i in range(count):
        let d=Int(v[2+3*i])
        for rev in range(d):let slot=d-1-rev;if slots[slot]==0:slots[slot]=Int(v[1+3*i]);total+=v[3+3*i];break
    var used=0
    for i in range(count):if slots[i]!=0:used+=1
    let bytes=9+used
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    o[0]=UInt8(used);let bits=UInt64(total)
    for i in range(8):o[1+i]=UInt8((bits>>UInt64(8*i))&255)
    var pos=9
    for i in range(count):if slots[i]!=0:o[pos]=UInt8(slots[i]);pos+=1
    return Int64(bytes)
