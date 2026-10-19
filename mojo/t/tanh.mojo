from std.math import exp,isfinite
@export("tanh")
fn tanh(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x< -10.0 or x>10.0:return -1.0e300
    return (2.0/(1.0+exp(-2.0*x)))-1.0
