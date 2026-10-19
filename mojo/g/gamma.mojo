from std.math import isfinite, sqrt

fn gamma_impl(x:Float64)->Float64:
    if x==0.5:return sqrt(3.14159265358979323846)
    if x==1.0:return 1.0
    return (x-1.0)*gamma_impl(x-1.0)

@export("gamma_recursive")
fn gamma_recursive(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x<0.5 or x>20.0 or x*2.0!=Float64(Int64(x*2.0)):return -1.0e300
    return gamma_impl(x)
