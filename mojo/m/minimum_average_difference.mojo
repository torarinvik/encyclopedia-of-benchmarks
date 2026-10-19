from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_average_difference")
fn minimum_average_difference(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>100000:return -1
    var total:Int64=0
    for i in range(Int(n)):if v[i]<0 or v[i]>100000:return -1;total+=v[i]
    var prefix:Int64=0;var best=9223372036854775807;var answer=0
    for i in range(Int(n)):
        prefix+=v[i];let left=prefix/Int64(i+1);let right=if i+1==Int(n):0 else:(total-prefix)/Int64(Int(n)-i-1)
        let diff=if left>right:left-right else:right-left
        if diff<best:best=diff;answer=i
    return Int64(answer)
