from std.math import exp

@export("elu")
fn elu(x:Float64,alpha:Float64) abi("C")->Float64:
    if x!=x or alpha!=alpha or x< -100.0 or x>100.0 or alpha< -1000000.0 or alpha>1000000.0:return -1.0e300
    if x<0.0:return alpha*(exp(x)-1.0)
    return x
