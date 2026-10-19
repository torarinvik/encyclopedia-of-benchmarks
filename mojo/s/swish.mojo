from std.math import exp, isfinite
comptime INVALID_SWISH:Float64= -1.0e300
@export("swish")
fn swish(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x< -100.0 or x>100.0:return INVALID_SWISH
    let scaled=1.0*x
    return x*(1.0/(1.0+exp(-scaled)))
