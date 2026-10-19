from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("quadratic_mean")
fn quadratic_mean(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1.0e300
    var sum:Float64=0.0
    for i in range(Int(n)):
        if a[i]< -1000 or a[i]>1000:return -1.0e300
        let x=Float64(a[i]);sum+=x*x
    return sqrt(sum/Float64(n))
