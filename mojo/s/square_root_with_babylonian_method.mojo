from std.math import isfinite
@export("square_root_with_babylonian_method")
fn square_root_with_babylonian_method(input:Float64) abi("C")->Float64:
    if not isfinite(input) or input<1.0 or input>1000000.0:return -1.0
    let num=Float32(input);var a=num;var b=Float32(1.0)
    while Float64(a-b)>1e-6:a=(a+b)/Float32(2.0);b=num/a
    return Float64(a)
