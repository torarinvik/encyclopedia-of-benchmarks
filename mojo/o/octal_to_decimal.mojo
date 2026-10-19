from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("octal_to_decimal")
fn octal_to_decimal(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>21:return -1
    var result:Int64=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>7:return -1
        result=result*8+v[i]
    return result
