from std.math import exp, isfinite
@export("gaussian_error_linear_unit")
fn gaussian_error_linear_unit(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x< -100.0 or x>100.0:return -1.0e300
    return x*(1.0/(1.0+exp(-1.702*x)))
