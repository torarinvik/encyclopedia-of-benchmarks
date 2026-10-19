from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mlfq_put(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p+b]=UInt8((u>>(8*b))&255)
@export("mlfqscheduler")
fn mlfqscheduler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>55 or v[0]<1 or v[0]>4 or v[1]<0 or v[1]>16:return -1
    let levels=Int(v[0]);let count=Int(v[1]);if Int(n)!=2+levels+3*count:return -1
    var quantum=InlineArray[Int64,4](fill=0);var pid=InlineArray[Int64,16](fill=0);var rem=InlineArray[Int64,16](fill=0)
    for l in range(levels):
        let q=v[2+l]
        if q<1 or q>32:return -1
        quantum[l]=q
    let off=2+levels
    for i in range(count):
        let p=v[off+3*i];let burst=v[off+3*i+1];let arrival=v[off+3*i+2]
        if p < -2147483648 or p>2147483647 or burst<0 or burst>1000 or arrival<0 or arrival>1000000:return -1
        pid[i]=p;rem[i]=burst
    var queues=InlineArray[Int64,64](fill=0);var qcount=InlineArray[Int64,4](fill=0)
    for i in range(count):queues[i]=Int64(i)
    qcount[0]=Int64(count)
    var donepid=InlineArray[Int64,16](fill=0);var donetime=InlineArray[Int64,16](fill=0);var completions=0;var now:Int64=0
    while True:
        var active=0
        for l in range(levels):active+=Int(qcount[l])
        if active==0:break
        for l in range(levels):
            let queued=Int(qcount[l])
            if queued==0:continue
            let proc=Int(queues[l*16]);
            for j in range(1,queued):queues[l*16+j-1]=queues[l*16+j]
            qcount[l]-=1
            let slice=if quantum[l]<rem[proc]:quantum[l] else:rem[proc]
            now+=slice;rem[proc]-=slice
            if rem[proc]==0:donepid[completions]=pid[proc];donetime[completions]=now;completions+=1
            else:
                let dest=if l+1<levels:l+1 else:l;let base=dest*16+Int(qcount[dest]);queues[base]=Int64(proc);qcount[dest]+=1
    let elems=2+2*completions;let bytes=elems*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mlfq_put(out,0,now);mlfq_put(out,8,Int64(completions))
    for i in range(completions):mlfq_put(out,16+16*i,donepid[i]);mlfq_put(out,24+16*i,donetime[i])
    return Int64(elems)
