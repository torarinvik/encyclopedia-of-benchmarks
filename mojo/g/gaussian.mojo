from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp, sqrt

@export("gaussian")
fn gaussian(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let x=v[0];let mu=v[1];let sigma=v[2]
    if x< -100 or x>100 or mu< -100 or mu>100 or sigma<1 or sigma>100:return -1.0e300
    let pi=3.14159265358979323846;let diff=x-mu;let sq=sigma*sigma
    let norm=1.0/sqrt(2.0*pi*Float64(sq));let exponent= -Float64(diff*diff)/Float64(2*sq)
    return norm*exp(exponent)
