from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("job_sequence_with_deadline")
fn job_sequence_with_deadline(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64 or n!=c_size_t(1+2*v[0]):return -1
    let count=Int(v[0]);var d=InlineArray[Int64,64](fill=0);var r=InlineArray[Int64,64](fill=0);var order=InlineArray[Int,64](fill=0)
    for i in range(count):d[i]=v[1+2*i];r[i]=v[2+2*i];if d[i]< -1 or d[i]>64 or r[i]< -1000000 or r[i]>1000000:return -1;order[i]=i
    for i in range(1,count):
        let key=order[i];var j=i
        while j>0 and r[order[j-1]]<r[key]:order[j]=order[j-1];j-=1
        order[j]=key
    var kept:Int64=0
    for i in range(count):if d[order[i]]>=i+1:kept+=1
    return kept
