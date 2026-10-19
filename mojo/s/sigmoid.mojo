from std.math import exp
@export("sigmoid")
fn sigmoid(x:Float64) abi("C")->Float64:
    if x< -20 or x>20:return -1.0e300
    return 1.0/(1.0+exp(-x))
