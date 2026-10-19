from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pairs_with_given_sum")
fn pairs_with_given_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -2
    for i in range(Int(n)):if v[i] < -2147483648 or v[i]>2147483647:return -2
    var count:Int64=0
    for i in range(1,Int(n)):for j in range(i+1,Int(n)):if v[i]+v[j]==v[0]:count+=1
    return count
