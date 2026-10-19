from std.math import fabs

@export("softsign")
fn softsign(x:Float64) abi("C")->Float64:
    if x!=x or x< -1.0e100 or x>1.0e100:return -1.0e300
    return x/(1.0+fabs(x))
