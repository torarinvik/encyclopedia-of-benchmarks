from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_largest_by_sort")
fn kth_largest_by_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>513:return -1
    let k=a[0];let count=Int(n)-1
    if k<1 or k>count:return -1
    var v=InlineArray[Int64,512]()
    for i in range(count):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        v[i]=a[i+1]
    # In-place heapsort over the private copy.
    for start in range(count//2-1,-1,-1):
        var root=start
        while 2*root+1<count:
            var child=2*root+1
            if child+1<count and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let t=v[root];v[root]=v[child];v[child]=t;root=child
    for end in range(count-1,0,-1):
        let t=v[0];v[0]=v[end];v[end]=t;var root=0
        while 2*root+1<end:
            var child=2*root+1
            if child+1<end and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let q=v[root];v[root]=v[child];v[child]=q;root=child
    return v[count-Int(k)]
