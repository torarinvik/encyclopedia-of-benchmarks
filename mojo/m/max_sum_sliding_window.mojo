from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_sum_sliding_window")
fn max_sum_sliding_window(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>100002:return -9223372036854775808
    let count=v[0];let k=v[1]
    if count<1 or count>100000 or k<1 or k>count or n!=c_size_t(count+2):return -9223372036854775808
    var current:Int64=0
    for i in range(Int(count)):
        let x=v[i+2];if x< -1000000000 or x>1000000000:return -9223372036854775808
        if i<Int(k):current+=x
    var best=current
    for i in range(Int(count-k)):current=current-v[i+2]+v[i+Int(k)+2];if current>best:best=current
    return best
