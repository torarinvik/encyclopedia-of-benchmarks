from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("max_values")
fn max_values(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -9223372036854775808
    let count=v[0]
    if count<1 or count>256 or n!=c_size_t(count+1):return -9223372036854775808
    var maximum=v[1]
    if maximum< -2147483648 or maximum>2147483647:return -9223372036854775808
    for i in range(2,Int(n)):
        let x=v[i]
        if x< -2147483648 or x>2147483647:return -9223372036854775808
        if x>maximum:maximum=x
    return maximum
