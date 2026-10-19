from std.math import pow, isfinite
@export("prefix_conversions")
fn prefix_conversions(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value< -1000000 or value>1000000 or from!=Float64(Int(from)) or to!=Float64(Int(to)):return -1.0e300
    let a=Int(from);let b=Int(to)
    if a<0 or a>27 or b<0 or b>27 or ((a<20)!=(b<20)):return -1.0e300
    var ex=InlineArray[Int,28](24,21,18,15,12,9,6,3,2,1,-1,-2,-3,-6,-9,-12,-15,-18,-21,-24,8,7,6,5,4,3,2,1)
    if a<20:return value*pow(10.0,Float64(ex[a]-ex[b]))
    return value*pow(2.0,Float64((ex[a]-ex[b])*10))
