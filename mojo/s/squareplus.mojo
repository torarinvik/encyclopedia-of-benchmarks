from std.math import isfinite, sqrt
comptime BAD:Float64= -1.0e300
@export("squareplus")
fn squareplus(x:Float64,beta:Float64) abi("C")->Float64:
    if not isfinite(x) or not isfinite(beta) or x< -10000 or x>10000 or beta<0.25 or beta>10000:return BAD
    return (x+sqrt(x*x+beta))/2.0
