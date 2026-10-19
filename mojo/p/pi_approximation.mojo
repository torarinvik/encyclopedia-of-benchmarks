from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pi_approximation")
fn pi_approximation(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    var inside=0
    for i in range(Int(n)):let x=v[2*i];let y=v[2*i+1];if x*x+y*y<=1.0:inside+=1
    return 4.0*Float64(inside)/Float64(n)
