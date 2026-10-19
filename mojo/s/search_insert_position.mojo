from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("search_insert_position")
fn search_insert_position(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let t=a[0]
    if t< -2147483648 or t>2147483647:return -1
    for i in range(1,Int(n)):
        if a[i]< -2147483648 or a[i]>2147483647 or (i>1 and a[i]<=a[i-1]):return -1
    var lo=0;var hi=Int(n)-1
    while lo<hi:
        let mid=lo+(hi-lo)/2
        if a[mid+1]<t:lo=mid+1
        else:hi=mid
    return Int64(lo)
