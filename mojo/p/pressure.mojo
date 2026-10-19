from std.math import isfinite
@export("pressure")
fn pressure(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value< -1000000 or value>1000000 or from!=Float64(Int(from)) or to!=Float64(Int(to)):return -1.0
    let a=Int(from);let b=Int(to)
    if a<0 or a>5 or b<0 or b>5:return -1.0
    var factor=InlineArray[Float64,6](1.0,1000.0,1000000.0,100000.0,101325.0,6894.757293168)
    return (value*factor[a])/factor[b]
