from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("job_sequencing_with_deadline")
fn job_sequencing_with_deadline(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<1 or v[0]>32:return -1
    let count=Int(v[0]);if n!=c_size_t(1+2*count):return -1
    var d=InlineArray[Int64,32](fill=0);var p=InlineArray[Int64,32](fill=0);var order=InlineArray[Int,32](fill=0)
    for i in range(count):d[i]=v[1+2*i];p[i]=v[2+2*i];if d[i]<0 or d[i]>32 or p[i]<0 or p[i]>1000000:return -1;order[i]=i
    for i in range(1,count):
        let key=order[i];var j=i
        while j>0 and p[order[j-1]]<p[key]:order[j]=order[j-1];j-=1
        order[j]=key
    var slots=InlineArray[Bool,33](fill=False);var num:Int64=0;var total:Int64=0
    for k in range(count):
        let i=order[k]
        for rev in range(Int(d[i])):let slot=Int(d[i])-rev;if not slots[slot]:slots[slot]=True;num+=1;total+=p[i];break
    return num*32000001+total
