from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mh_store(mut bytes:InlineArray[UInt8,4096],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):bytes[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("max_heap")
fn max_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>512:return -1
    let ops=Int(v[0]);if n!=c_size_t(1+ops*2):return -1
    var inserts=0;var words=0
    for i in range(ops):
        let op=v[1+2*i];let value=v[2+2*i]
        if op<0 or op>2:return -1
        if op==0:inserts+=1;if inserts>256 or value< -2147483648 or value>2147483647:return -1
        else:if value!=0:return -1;words+=1
    if cap<c_size_t(words*8) or (words>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var heap=InlineArray[Int64,256](fill=0);var size=0;var staged=InlineArray[UInt8,4096](fill=0);var outpos=0
    for i in range(ops):
        let op=v[1+2*i];let value=v[2+2*i]
        if op==0:
            var at=size;size+=1;heap[at]=value
            while at>0:
                let parent=(at-1)/2
                if heap[parent]>=heap[at]:break
                let temp=heap[parent];heap[parent]=heap[at];heap[at]=temp;at=parent
            continue
        var result:Int64= -9223372036854775808
        if size>0:
            result=heap[0]
            if op==2:
                size-=1;heap[0]=heap[size];var at=0
                while at<size/2:
                    var child=at*2+1
                    if child+1<size and heap[child+1]>heap[child]:child+=1
                    if heap[at]>=heap[child]:break
                    let temp=heap[at];heap[at]=heap[child];heap[child]=temp;at=child
        mh_store(mut staged,outpos*8,result);outpos+=1
    for i in range(words*8):out[i]=staged[i]
    return Int64(words)
