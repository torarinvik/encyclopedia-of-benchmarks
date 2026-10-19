from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("relativistic_velocity_summation")
fn relativistic_velocity_summation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    let a=v[0];let b=v[1];let c:Int64=299792458
    if a< -c or a>c or b<-(c-1) or b>c-1:return -1.0e300
    let numerator=a+b;let denominator=1.0+Float64(a*b)/Float64(c*c)
    return Float64(numerator)/denominator
