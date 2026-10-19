from std.math import exp, log

@export("softplus")
fn softplus(x:Float64) abi("C")->Float64:
    if x!=x or x< -100.0 or x>100.0:return -1.0e300
    return log(1.0+exp(x))
