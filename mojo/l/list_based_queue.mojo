from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("list_based_queue")
fn list_based_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<0 or v[0]>32:return -1
    let ops=Int(v[0]);var q=InlineArray[Int32,32](fill=0);var words=InlineArray[Int64,64](fill=0);var allocated=0;var wc=0;var pos=1;var size=0
    for _ in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos>=Int(n) or v[pos] < -2147483648 or v[pos]>2147483647 or allocated>=32:return -1
            let x=v[pos];pos+=1;q[allocated]=Int32(x);allocated+=1;size+=1;words[wc]=0;words[wc+1]=1;wc+=2
        elif op==1:
            if size==0:return -1
            words[wc]=1;words[wc+1]=q[0];wc+=2
            for i in range(size-1):q[i]=q[i+1]
            size-=1
        elif op==2:
            if size==0:return -1
            words[wc]=2;words[wc+1]=q[0];wc+=2
        elif op==3:size=0;words[wc]=3;words[wc+1]=1;wc+=2
        elif op==4:words[wc]=4;words[wc+1]=Int64(size==0);wc+=2
        elif op==5:words[wc]=5;words[wc+1]=0;wc+=2
        else:return -1
    if pos!=Int(n) or wc>64:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(wc*8):return -2
    for i in range(wc):
        let b=UInt64(words[i])
        for j in range(8):out[i*8+j]=UInt8((b>>(8*j))&255)
    return Int64(wc*8)
