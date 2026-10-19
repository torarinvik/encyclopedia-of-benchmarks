from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("period_of_pendulum")
fn period_of_pendulum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>1000:return -1.0e300
    return (2.0*3.141592653589793238462643383279502884)*sqrt(Float64(v[0])/9.80665)
