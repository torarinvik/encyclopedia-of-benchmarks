from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("priority_queue_sort")
fn priority_queue_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);var heap=InlineArray[Int32,128](fill=0);var hs=0
    for i in range(count):
        if v[i+1]< -2147483648 or v[i+1]>2147483647:return -1
        var x=i;heap[x]=Int32(v[i+1]);hs+=1
        while x>0:
            let p=(x-1)//2
            if heap[p]<=heap[x]:break
            let t=heap[p];heap[p]=heap[x];heap[x]=t;x=p
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*4):return -2
    for i in range(count):
        let value=heap[0];hs-=1
        if hs>0:
            heap[0]=heap[hs];var x=0
            while 2*x+1<hs:
                var c=2*x+1
                if c+1<hs and heap[c+1]<heap[c]:c+=1
                if heap[x]<=heap[c]:break
                let t=heap[x];heap[x]=heap[c];heap[c]=t;x=c
        let bits=UInt32(value)
        for b in range(4):out[i*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(count*4)
