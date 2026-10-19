from std.math import isfinite
comptime BAD:Float64= -1.0
fn sqrt_newton(x2:Float32,y:Float32)->Float32:
    let p1=x2*y;let p2=p1*y;let correction=Float32(1.5)-p2;return y*correction
@export("go_sqrt_f32")
fn go_sqrt_f32(value:Float64) abi("C")->Float64:
    if not isfinite(value) or value<1e-6 or value>1e6:return BAD
    let x=Float32(value);let x2=x*Float32(0.5);let bits=bitcast[UInt32](x);let seed=UInt32(0x5f3759df)-(bits>>1)
    var y=bitcast[Float32](seed);y=sqrt_newton(x2,y);y=sqrt_newton(x2,y)
    return Float64(Float32(1.0)/y)
