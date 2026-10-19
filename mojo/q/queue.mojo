from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("queue")
fn queue(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or n%2!=0:return -1
    if n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    var q=InlineArray[Int64,256]();var head=0;var size=0;var checksum:Int64=0;var observations:Int64=0
    for i in range(Int(n/2)):
        let op=a[2*i];let value=a[2*i+1]
        if op<0 or op>5:return -1
        if op==0:
            if value< -1000000 or value>1000000 or size>=256:return -1
            q[(head+size)%256]=value;size+=1
        else:
            if value!=0:return -1
            var result:Int64=0
            if op==1:
                if size==0:return -1
                result=q[head];head=(head+1)%256;size-=1
            elif op==2:
                if size==0:return -1
                result=q[head]
            elif op==3:
                if size==0:return -1
                result=q[(head+size-1)%256]
            elif op==4:result=1 if size==0 else 0
            else:result=size
            observations+=1;checksum+=(Int64(i)+1)*(result+1000000)
    for i in range(size):checksum+=(Int64(n/2)+Int64(i)+1)*(q[(head+i)%256]+1000000)
    return checksum
