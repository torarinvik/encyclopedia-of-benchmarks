from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("priority_queues")
fn priority_queues(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>515 or v[0]<1 or v[0]>128 or v[1]<0 or v[1]>256 or n!=c_size_t(2+2*v[1]):return -1
    let capacity=Int(v[0]);let ops=Int(v[1])
    for i in range(ops):
        let op=v[2+2*i];let arg=v[3+2*i]
        if op<0 or op>5 or (op==0 and (arg< -2147483648 or arg>2147483647)) or (op!=0 and arg!=0):return -1
    if ops==0:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(ops*16):return -2
    var heap=InlineArray[Int32,129](fill=0);var size=0
    for opi in range(ops):
        let op=v[2+2*opi];let arg=v[3+2*opi];var status=Int64(0);var value=Int64(0)
        if op==0:
            if size==capacity:status=1
            else:
                size+=1;heap[size]=Int32(arg);var i=size
                while i>1 and heap[i//2]<heap[i]:let t=heap[i//2];heap[i//2]=heap[i];heap[i]=t;i//=2
        elif op==1:
            if size==0:status=2
            else:
                value=Int64(heap[1]);heap[1]=heap[size];heap[size]=0;size-=1;var i=1
                while 2*i<=size:
                    var c=2*i
                    if c<size and heap[c+1]>heap[c]:c+=1
                    if heap[i]>=heap[c]:break
                    let t=heap[i];heap[i]=heap[c];heap[c]=t;i=c
        elif op==2:value=Int64(heap[1]) if size>0 else 0
        elif op==3:value=1 if size==0 else 0
        elif op==4:value=1 if size==capacity else 0
        else:value=Int64(size)
        for w in range(2):
            let bits=UInt64(status if w==0 else value)
            for b in range(8):out[opi*16+w*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(ops*16)
