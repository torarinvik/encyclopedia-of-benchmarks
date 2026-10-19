from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stack_using_two_queues")
fn stack_using_two_queues(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let oc=v[0]
    if oc<0 or oc>128 or n!=c_size_t(1+2*oc):return -1
    var qa=InlineArray[Int64,128](fill=0);var qb=InlineArray[Int64,128](fill=0);var maina=True;var head=0;var tail=0
    var tags=InlineArray[Int64,128](fill=0);var results=InlineArray[Int64,128](fill=0);var rc=0
    for i in range(Int(oc)):
        let op=v[1+2*i];let x=v[2+2*i]
        if op==0:
            if x< -2147483648 or x>2147483647:return -1
            var temp=InlineArray[Int64,128](fill=0);var size=1;temp[0]=x
            if maina:
                for j in range(head,tail):temp[size]=qa[j];size+=1
                for j in range(size):qb[j]=temp[j]
            else:
                for j in range(head,tail):temp[size]=qb[j];size+=1
                for j in range(size):qa[j]=temp[j]
            head=0;tail=size;maina=not maina
        elif op==1:
            if x!=0 or head==tail:return -1
            tags[rc]=0;results[rc]=qa[head] if maina else qb[head];rc+=1;head+=1
        elif op==2:
            if x!=0:return -1
            if head==tail:tags[rc]=1;results[rc]=0
            else:tags[rc]=0;results[rc]=qa[head] if maina else qb[head]
            rc+=1
        else:return -1
    let bytes=rc*16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rc):
        for w in range(2):let x=tags[i] if w==0 else results[i];let bits=bitcast[UInt64](x);for b in range(8):o[16*i+8*w+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
