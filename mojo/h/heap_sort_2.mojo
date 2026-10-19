from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("heap_sort_2")
fn heap_sort_2(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n==0 or a==UnsafePointer[Int64,MutAnyOrigin]():return
    let len=Int(n)
    for i in range(1,len):
        var child=i
        while child>0:
            let parent=(child-1)//2
            if a[parent]>=a[child]:break
            let t=a[parent];a[parent]=a[child];a[child]=t;child=parent
    for end0 in range(len-1):
        let end=len-1-end0;let t=a[0];a[0]=a[end];a[end]=t;var root=0
        while root*2+1<end:
            var child=root*2+1
            if child+1<end and a[child]<a[child+1]:child+=1
            if a[root]>=a[child]:break
            let v=a[root];a[root]=a[child];a[child]=v;root=child
