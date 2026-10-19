from std.math import isfinite
comptime BAD:Float64= -1.0e300
@export("square_root_with_newton_raphson_method")
fn square_root_with_newton_raphson_method(input:Float64) abi("C")->Float64:
    if not isfinite(input) or input<1.0 or input>2147483647.0 or input!=Float64(Int64(input)):return BAD
    var guess=input;var root=0.5*(guess+input/guess)
    while abs(root-guess)>1e-7:guess=root;root=0.5*(guess+input/guess)
    return root
