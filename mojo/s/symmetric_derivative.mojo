from std.ffi import c_size_t
from std.math import exp, isfinite, sin
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD_DERIVATIVE:Float64= -1.0e300
@export("symmetric_derivative")
fn symmetric_derivative(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return BAD_DERIVATIVE
    let id=v[0];let xn=v[1]
    if (id!=0 and id!=1) or xn< -6300000000 or xn>6300000000:return BAD_DERIVATIVE
    let x=Float64(xn)/1000000000.0;let h=1.0e-10
    var upper=0.0;var lower=0.0
    if id==0:upper=sin(x+h);lower=sin(x-h)
    else:upper=exp(x+h);lower=exp(x-h)
    return (upper-lower)/(2.0*h)
