from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_appearing_odd_times")
fn number_appearing_odd_times(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4096:return -2147483649
    var value:Int32=0
    for i in range(Int(n)):
        if a[i]< -2147483648 or a[i]>2147483647:return -2147483649
        value=value^Int32(a[i])
    return Int64(value)
