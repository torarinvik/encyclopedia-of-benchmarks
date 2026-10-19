from std.math import isfinite

@export("leaky_relu")
fn leaky_relu(x:Float64,alpha:Float64) abi("C")->Float64:
    if not isfinite(x) or not isfinite(alpha) or x < -1.0e6 or x > 1.0e6 or alpha < -1.0e6 or alpha > 1.0e6:return -1.0e300
    if x<0.0:return x*alpha
    return x
