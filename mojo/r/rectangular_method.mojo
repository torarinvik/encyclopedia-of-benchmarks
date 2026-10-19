from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import cos,exp,sin
fn rect_integrand(x:Float64)->Float64:return (exp(x)/2.0)*(cos(x)-sin(x))
@export("rectangular_method")
fn rectangular_method(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let aq=v[0];let bq=v[1];let count=v[2];let rule=v[3]
    if aq< -64 or aq>=bq or bq>64 or count<1 or count>64 or (bq-aq)%count!=0 or (rule!=0 and rule!=1):return -1.0e300
    let a=Float64(aq)/4.0;let b=Float64(bq)/4.0;let step=(b-a)/Float64(count);var x=a;var total:Float64=0.0
    for _ in range(Int(count)):
        if rule==0:total+=rect_integrand(x)*step;x+=step
        else:x+=step;total+=rect_integrand(x)*step
    return total
