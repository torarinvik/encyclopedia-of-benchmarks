@export("lerp")
fn lerp(start:Float64,end:Float64,t:Float64) abi("C")->Float64:
    return start+t*(end-start)
