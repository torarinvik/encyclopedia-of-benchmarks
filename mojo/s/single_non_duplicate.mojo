from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("single_non_duplicate")
fn single_non_duplicate(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1025 or n%2==0:return -2147483649
    var lo=0;var hi=Int(n)-1
    while lo<hi:
        let mid=lo+(hi-lo)/2
        if mid%2==0:
            if a[mid]==a[mid+1]:lo=mid+2
            else:hi=mid
        else:
            if a[mid]==a[mid-1]:lo=mid+1
            else:hi=mid-1
    return a[lo]
