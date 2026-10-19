from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("wave_sort")
fn wave_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let count=Int(n);var v=InlineArray[Int32,4096]()
    for i in range(count):if a[i]< -2147483648 or a[i]>2147483647:return -1;else:v[i]=Int32(a[i])
    if cap<c_size_t(n*4) or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for root0 in range(count/2):
        var root=count/2-1-root0
        while root<count/2:
            var child=root*2+1
            if child+1<count and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let t=v[root];v[root]=v[child];v[child]=t;root=child
    for e0 in range(max(0,count-1)):
        let end=count-1-e0;let t=v[0];v[0]=v[end];v[end]=t;var root=0
        while root<end/2:
            var child=root*2+1
            if child+1<end and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let z=v[root];v[root]=v[child];v[child]=z;root=child
    for i in range(0,count-1,2):let t=v[i];v[i]=v[i+1];v[i+1]=t
    for i in range(count):let bits=bitcast[UInt32](v[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(n)
