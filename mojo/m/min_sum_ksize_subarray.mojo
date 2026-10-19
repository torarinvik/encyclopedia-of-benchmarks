from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("min_sum_ksize_subarray")
fn min_sum_ksize_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>100002:return -9223372036854775808
    let count=v[0];let k=v[1]
    if count<0 or count>100000 or k<0 or k>100000 or Int(n)!=Int(count)+2:return -9223372036854775808
    for i in range(Int(count)):if v[i+2] < -10000 or v[i+2]>10000:return -9223372036854775808
    if k>count:return -1
    if k==0:return 0
    var sum:Int64=0
    for i in range(Int(k)):sum+=v[i+2]
    var best=sum
    for i in range(Int(k),Int(count)):
        sum+=v[i+2]-v[i-Int(k)+2]
        if sum<best:best=sum
    return best
