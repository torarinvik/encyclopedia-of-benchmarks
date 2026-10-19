from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mlfq_i32(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+4*b]=UInt8((u>>(8*b))&255)
@export("multi_level_feedback_queue")
fn multi_level_feedback_queue(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>13:return -1
    let levels=Int(v[0]);let count=Int(v[1]);if levels<1 or levels>4 or count<0 or count>8 or Int(n)!=2+levels-1+count:return -1
    var slices=InlineArray[Int32,3](fill=0);var pos=2
    for i in range(levels-1):if v[pos]<1 or v[pos]>16:return -1;slices[i]=v[pos];pos+=1
    var rem=InlineArray[Int32,8](fill=0);var wait=InlineArray[Int32,8](fill=0);var turn=InlineArray[Int32,8](fill=0);var stop=InlineArray[Int32,8](fill=0);var finished=InlineArray[Int32,8](fill=0);var nf=0;var now=0
    for i in range(count):if v[pos]<1 or v[pos]>16:return -1;rem[i]=v[pos];pos+=1
    var active=InlineArray[Int64,8](fill=0)
    for i in range(count):active[i]=1
    for level in range(levels-1):
        var next=InlineArray[Int64,8](fill=0)
        for i in range(count):
            if active[i]!=0:
                wait[i]+=now-stop[i]
                if rem[i]>slices[level]:now+=slices[level];rem[i]-=slices[level];stop[i]=now;next[i]=1
                else:now+=rem[i];rem[i]=0;stop[i]=now;turn[i]=now;finished[nf]=Int32(i);nf+=1
        active=next
    for i in range(count):
        if active[i]!=0:wait[i]+=now-stop[i];now+=rem[i];rem[i]=0;stop[i]=now;turn[i]=now;finished[nf]=Int32(i);nf+=1
    if nf!=count:return -1
    let bytes=(1+4*count)*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mlfq_i32(o,0,Int32(count))
    for k in range(count):let i=Int(finished[k]);let p=4+16*k;mlfq_i32(o,p,Int32(i));mlfq_i32(o,p+4,wait[i]);mlfq_i32(o,p+8,turn[i]);mlfq_i32(o,p+12,stop[i])
    return Int64(bytes)
