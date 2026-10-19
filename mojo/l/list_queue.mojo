from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("list_queue")
fn list_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64:return -1
    let ops=Int(v[0]);var q=InlineArray[Int32,10](fill=0);var words=InlineArray[Int32,130](fill=0);var wc=1;var qc=0;var pos=1;var size=0
    for _ in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos>=Int(n) or v[pos] < -2147483648 or v[pos]>2147483647 or size>=10:return -1
            q[size]=Int32(v[pos]);size+=1;pos+=1
        elif op==1:
            if size==0:words[wc]=3;words[wc+1]=0;wc+=2
            else:
                let x=q[0]
                for i in range(size-1):q[i]=q[i+1]
                size-=1;words[wc]=1;words[wc+1]=x;wc+=2
            qc+=1
        elif op==2:words[wc]=2;words[wc+1]=Int32(size);wc+=2;qc+=1
        else:return -1
    if pos!=Int(n) or wc+1+size>130:return -1
    words[0]=Int32(qc);words[wc]=Int32(size);wc+=1
    for i in range(size):words[wc]=q[i];wc+=1
    let bytes=wc*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(wc):
        let b=bitcast[UInt32](words[i])
        for j in range(4):out[i*4+j]=UInt8((b>>(8*j))&255)
    return Int64(bytes)
