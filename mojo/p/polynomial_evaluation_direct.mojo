from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("polynomial_evaluation_direct")
fn polynomial_evaluation_direct(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>10:return -9223372036854775808
    let count=v[0];let x=v[1]
    if count<0 or count>8 or n!=c_size_t(count+2) or x< -10 or x>10:return -9223372036854775808
    for i in range(Int(count)):if v[i+2]< -1000 or v[i+2]>1000:return -9223372036854775808
    var total=Int64(0)
    for i in range(Int(count)):
        var power=Int64(1)
        for _ in range(i):power*=x
        total+=v[i+2]*power
    return total
