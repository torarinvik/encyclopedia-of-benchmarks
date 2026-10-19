from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_smallest_heap")
fn kth_smallest_heap(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or a[0]<1 or a[0]>=n:return -1
    let k=Int(a[0]);let count=Int(n)-1;var v=InlineArray[Int64,64]()
    for i in range(count):if a[i+1]< -100000 or a[i+1]>100000:return -1;v[i]=a[i+1]
    for i in range(k//2-1,-1,-1):
        var p=i
        while 2*p+1<k:
            var c=2*p+1;if c+1<k and v[c+1]>v[c]:c+=1
            if v[p]>=v[c]:break
            let t=v[p];v[p]=v[c];v[c]=t;p=c
    for i in range(k,count):
        if v[i]<=v[0]:
            v[0]=v[i];var p=0
            while 2*p+1<k:
                var c=2*p+1;if c+1<k and v[c+1]>v[c]:c+=1
                if v[p]>=v[c]:break
                let t=v[p];v[p]=v[c];v[c]=t;p=c
    return v[0]
