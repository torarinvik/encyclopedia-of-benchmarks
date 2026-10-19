from std.math import isfinite
@export("pressure_conversions")
fn pressure_conversions(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value< -1000000 or value>1000000 or from!=Float64(Int(from)) or to!=Float64(Int(to)):return -1.0
    let a=Int(from);let b=Int(to)
    if a<0 or a>7 or b<0 or b>7:return -1.0
    var f=InlineArray[Float64,8](1.0,0.0000098,0.986923,0.00986923,9.86923,0.068046,0.0334211,0.00131579)
    var t=InlineArray[Float64,8](1.0,101325.0,1.01325,101.325,0.101325,14.6959,29.9213,760.0)
    return (value*f[a])*t[b]
