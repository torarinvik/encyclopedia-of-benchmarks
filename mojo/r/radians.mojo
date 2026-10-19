@export("radians")
fn radians(x:Float64) abi("C")->Float64:
    if not (x>=-1000000.0 and x<=1000000.0):return -1.0e300
    return x/(180.0/3.141592653589793)
