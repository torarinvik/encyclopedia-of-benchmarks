from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_sum_ksize_subarray")
fn max_sum_ksize_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>64:return -1
    let count=Int(n)-1;let k=v[Int(n)-1]
    if k<0 or k>count:return -1
    for i in range(count):if v[i]< -1000000 or v[i]>1000000:return -1
    if k==0:return 0
    var sum:Int64=0
    for i in range(Int(k)):sum+=v[i]
    var best=sum
    for i in range(Int(k),count):sum+=v[i]-v[i-Int(k)];if sum>best:best=sum
    return best
