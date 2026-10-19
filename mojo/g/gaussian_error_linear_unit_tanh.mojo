from std.math import exp, isfinite, pow, sqrt
@export("gaussian_error_linear_unit_tanh")
fn gaussian_error_linear_unit_tanh(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x< -100.0 or x>100.0:return -1.0e300
    let pi=3.14159265358979323846;let e=2.71828182845904523536
    let scale=sqrt(2.0/pi);let z=scale*(x+0.044715*pow(x,3.0))
    let tanh=2.0/(1.0+pow(e,-2.0*z))-1.0
    return x*0.5*(1.0+tanh)
