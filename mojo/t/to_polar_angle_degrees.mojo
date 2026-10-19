from std.math import atan, isfinite
@export("to_polar_angle_degrees")
fn to_polar_angle_degrees(x:Float64,y:Float64) abi("C")->Float64:
    if not isfinite(x) or not isfinite(y) or x< -1000000.0 or x>1000000.0 or y< -1000000.0 or y>1000000.0 or (x==0.0 and y==0.0):return -1.0e300
    let pi=3.141592653589793238462643383279502884
    var theta:Float64=0.0
    if x>=0.0:theta=atan(y/x)
    else:theta=atan(y/x)+pi
    return theta*(180.0/pi)
