from std.math import exp
@export("sigmoid_without_inbuilt")
fn sigmoid_without_inbuilt(x:Float64,a:Float64) abi("C")->Float64:
    if x< -10 or x>10 or a< -10 or a>10:return -1.0e300
    return 1.0/(1.0+exp(-(a*x)))
