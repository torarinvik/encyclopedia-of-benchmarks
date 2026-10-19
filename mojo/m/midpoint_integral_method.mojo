from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt, log, exp
fn mim_f(id:Int64,x:Float64)->Float64:
    if id==0:return sqrt(x)+log(x)
    if id==1:return exp(-x)*(4.0-x*x)
    if id==2:return sqrt(2.0*x*x*x+3.0)
    return x+log(2.0*x+1.0)
@export("midpoint_integral_method")
fn midpoint_integral_method(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let id=v[0];let steps=v[1];let a=v[2];let b=v[3]
    if id<0 or id>3 or steps<2 or steps>64 or steps%2!=0 or a<0 or a>=b or b>10000:return -1.0e300
    let lo=Float64(a)/1000.0;let hi=Float64(b)/1000.0;let h=(hi-lo)/Float64(steps);var x=lo;var sum=0.0
    for _ in range(Int(steps)):sum+=mim_f(id,x+h/2.0);x+=h
    return sum*h
