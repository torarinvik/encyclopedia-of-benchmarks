from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("negative_binary_base_to_int")
fn negative_binary_base_to_int(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>63:return -1
    var v:Int64=0
    for i in range(Int(n)):
        let bit=a[i];if bit!=0 and bit!=1:return -1
        let wide=Int128(v)*Int128(-2)+Int128(bit)
        if wide>Int128(9223372036854775807) or wide<Int128(-9223372036854775808):return -1
        v=Int64(wide)
    return v
