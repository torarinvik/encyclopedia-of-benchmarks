from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("heap_max_push_peek_pop")
fn heap_max_push_peek_pop(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257 or a[0]<1 or a[0]>256 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0]);var heap=InlineArray[Int64,256](fill=0)
    for i in range(count):
        if a[i+1]<1 or a[i+1]>1000000000:return -1
        heap[i]=a[i+1];var cur=i
        while cur>0:
            let par=(cur-1)//2
            if heap[par]>=heap[cur]:break
            let t=heap[par];heap[par]=heap[cur];heap[cur]=t;cur=par
    let bytes=count*8
    if cap<c_size_t(bytes) or out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(count):
        let u=bitcast[UInt64](heap[0])
        for b in range(8):out[i*8+b]=UInt8((u>>UInt(8*b))&255)
        let end=count-i-1;heap[0]=heap[end];var root=0
        while root*2+1<end:
            var child=root*2+1
            if child+1<end and heap[child+1]>heap[child]:child+=1
            if heap[root]>=heap[child]:break
            let t=heap[root];heap[root]=heap[child];heap[child]=t;root=child
    return Int64(bytes)
