from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_largest_element")
fn kth_largest_element(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>513:return -1
    let k=a[0];let count=Int(n)-1
    if k<1 or k>count:return -1
    var v=InlineArray[Int64,512]()
    for i in range(count):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        v[i]=a[i+1]
    let target=Int(k)-1;var lo=0;var hi=count-1
    while lo<=hi:
        let pivot=v[hi];var store=lo
        for i in range(lo,hi):if v[i]>pivot:let t=v[i];v[i]=v[store];v[store]=t;store+=1
        v[store]=pivot
        if store==target:return v[store]
        if store<target:lo=store+1
        else:hi=store-1
    return -1
