from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mhbes_store(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p+b]=UInt8((u>>(8*b))&255)
@export("min_heap_bulk_extract_sorted")
fn min_heap_bulk_extract_sorted(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4096 or v[0]<1 or v[0]>4095 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var heap=InlineArray[Int64,4095](fill=0);var sorted=InlineArray[Int64,4095](fill=0)
    for i in range(count):
        let x=v[i+1]
        if x < -2147483648 or x>2147483647:return -1
        var j=i
        while j>0 and heap[(j-1)//2]>x:heap[j]=heap[(j-1)//2];j=(j-1)//2
        heap[j]=x
    for outi in range(count):
        sorted[outi]=heap[0];let last=heap[count-outi-1];var size=count-outi-1
        if size>0:
            var j=0
            while j*2+1<size:
                var ch=j*2+1
                if ch+1<size and heap[ch+1]<heap[ch]:ch+=1
                if heap[ch]>=last:break
                heap[j]=heap[ch];j=ch
            heap[j]=last
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    for i in range(count):mhbes_store(out,i*8,sorted[i])
    return Int64(count*8)
