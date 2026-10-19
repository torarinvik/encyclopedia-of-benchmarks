from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rh_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x)
    for j in range(4):o[at+j]=UInt8((b>>(8*j))&255)
@export("randomized_heap")
fn randomized_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64:return -1
    let ops=Int(v[0]);var heap=InlineArray[Int64,64](fill=0);var words=InlineArray[Int64,129](fill=0);var hs=0;var wc=1;var q=0;var pos=1
    for _ in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos>=Int(n) or v[pos]< -2147483648 or v[pos]>2147483647:return -1
            var i=hs;heap[i]=v[pos];pos+=1
            while i>0:
                let parent=(i-1)//2
                if heap[parent]<=heap[i]:break
                let t=heap[parent];heap[parent]=heap[i];heap[i]=t;i=parent
            hs+=1
        elif op==1 or op==2:
            if hs==0:return -1
            let value=heap[0]
            if op==2:
                hs-=1
                if hs>0:
                    heap[0]=heap[hs];var i=0
                    while True:
                        let left=2*i+1
                        if left>=hs:break
                        let right=left+1;let child=if right<hs and heap[right]<heap[left]:right else:left
                        if heap[i]<=heap[child]:break
                        let t=heap[i];heap[i]=heap[child];heap[child]=t;i=child
            words[wc]=op;words[wc+1]=value;wc+=2;q+=1
        elif op==3:words[wc]=3;words[wc+1]=Int64(hs==0);wc+=2;q+=1
        else:return -1
    if pos!=Int(n):return -1
    words[0]=Int64(q);let bytes=wc*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(wc):rh_put(o,i*4,Int32(words[i]))
    return Int64(bytes)
