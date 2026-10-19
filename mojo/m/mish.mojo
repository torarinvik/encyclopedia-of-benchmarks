from std.math import exp, log, tanh, isfinite
@export("mish")
fn mish(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x < -20.0 or x>20.0:return -1.0e300
    return x*tanh(log(1.0+exp(x)))
