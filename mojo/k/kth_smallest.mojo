from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_smallest")
fn kth_smallest(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258 or a[0]<1 or a[0]>256 or a[1]<1 or a[1]>a[0] or n!=c_size_t(2+a[0]):return -9223372036854775808
    let count=Int(a[0]);let target=Int(a[1])-1;var v=InlineArray[Int64,256]()
    for i in range(count):if a[2+i]< -2147483648 or a[2+i]>2147483647:return -9223372036854775808;v[i]=a[2+i]
    var lo=0;var hi=count-1
    while lo<=hi:
        let pivot=v[hi];var store=lo
        for i in range(lo,hi):if v[i]<pivot:let t=v[i];v[i]=v[store];v[store]=t;store+=1
        v[store]=pivot
        if store==target:return v[store]
        if store<target:lo=store+1
        else:hi=store-1
    return -9223372036854775808
