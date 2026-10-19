from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("min_values")
fn min_values(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257 or v[0]<1 or v[0]>256 or Int(n)!=Int(v[0])+1:return -9223372036854775808
    var best=v[1]
    if best < -2147483648 or best>2147483647:return -9223372036854775808
    for i in range(2,Int(n)):
        if v[i] < -2147483648 or v[i]>2147483647:return -9223372036854775808
        if v[i]<best:best=v[i]
    return best
