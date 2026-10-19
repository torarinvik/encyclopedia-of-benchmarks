from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mpq_i32(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p+b]=UInt8((u>>(8*b))&255)
@export("min_priority_queue")
fn min_priority_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130 or v[0]<0 or v[0]>64 or v[1]<0 or v[1]>64:return -1
    let capacity=Int(v[0]);let ops=Int(v[1]);var heap=InlineArray[Int32,64](fill=0);var size=0;var answers=InlineArray[Int32,128](fill=0);var q=0;var pos=2
    for _ in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos>=Int(n):return -1
            let x=v[pos];pos+=1
            if x < -2147483648 or x>2147483647 or size>=capacity:return -1
            var j=size
            while j>0 and heap[(j-1)//2]>Int32(x):heap[j]=heap[(j-1)//2];j=(j-1)//2
            heap[j]=Int32(x);size+=1
        elif op==1 or op==2:
            if size==0:return -1
            let value=heap[0]
            if op==2:
                size-=1
                if size>0:
                    let last=heap[size];var i=0
                    while i*2+1<size:
                        var ch=i*2+1
                        if ch+1<size and heap[ch+1]<heap[ch]:ch+=1
                        if heap[ch]>=last:break
                        heap[i]=heap[ch];i=ch
                    heap[i]=last
            answers[q]=if op==1:1 else:2;answers[q+1]=value;q+=2
        elif op==3 or op==4:
            answers[q]=if op==3:3 else:4;answers[q+1]=if op==3:Int32(1 if size==0 else 0) else:Int32(1 if size==capacity else 0);q+=2
        else:return -1
    if pos!=Int(n):return -1
    let words=1+q;let bytes=words*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mpq_i32(out,0,Int32(q//2))
    for i in range(q//2):mpq_i32(out,4+8*i,answers[2*i]);mpq_i32(out,8+8*i,answers[2*i+1])
    return Int64(bytes)
