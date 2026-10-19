from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("peak_index_in_mountain_array")
fn peak_index_in_mountain_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>100000:return -1
    var lo=0;var hi=Int(n)-1
    while lo<hi:let mid=lo+(hi-lo)/2;if v[mid]<v[mid+1]:lo=mid+1 else:hi=mid
    if lo==0 or lo+1==Int(n):return -1
    return Int64(lo)
