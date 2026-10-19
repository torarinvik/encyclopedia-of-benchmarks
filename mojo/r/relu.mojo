from std.math import isfinite,trunc
@export("relu")
fn relu(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x < -16777216.0 or x>16777216.0 or trunc(x)!=x:return -1.0e300
    return if x>0:x else:0.0
