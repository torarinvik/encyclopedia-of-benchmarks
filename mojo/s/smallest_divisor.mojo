from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("smallest_divisor")
fn smallest_divisor(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257:return -1
    let threshold=a[0];let count=Int(n)-1;if threshold<1 or threshold>1000000 or threshold<count:return -1
    for i in range(count):if a[i+1]<1 or a[i+1]>1000000:return -1
    var lo:Int64=1;var hi:Int64=1000000
    while lo<hi:
        let mid=(lo+hi)/2;var sum:Int64=0
        for i in range(count):sum+=(a[i+1]+mid-1)/mid
        if sum<=threshold:hi=mid
        else:lo=mid+1
    return lo
