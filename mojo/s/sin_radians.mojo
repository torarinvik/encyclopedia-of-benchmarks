from math import floor, abs
@export("sin_radians")
fn sin_radians(x:Float64) abi("C")->Float64:
    if not (x>=-1000000.0 and x<=1000000.0):return -1.0
    var y=(3.141592653589793/2.0)-x
    y*=1.0/(2.0*3.141592653589793);y-=0.25+floor(y+0.25)
    y*=16.0*(abs(y)-0.5);y+=0.225*y*(abs(y)-1.0)
    return y
