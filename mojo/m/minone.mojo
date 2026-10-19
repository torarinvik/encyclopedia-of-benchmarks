from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minone")
fn minone(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    var sum:Int64=0
    for i in range(Int(n)):
        let x=v[i]
        if x < -1000000 or x>1000000:return -1
        sum+=x*x
    return sum
