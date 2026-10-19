from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("peak_element")
fn peak_element(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>129 or v[0]<1 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1
    var lo=0;var hi=count-1
    while lo<=hi:
        let mid=lo+(hi-lo)/2
        if (mid==0 or v[mid]<=v[mid+1]) and (mid==count-1 or v[mid+2]<=v[mid+1]):return Int64(mid)
        if mid>0 and v[mid]>v[mid+1]:hi=mid-1 else:lo=mid+1
    return -1
