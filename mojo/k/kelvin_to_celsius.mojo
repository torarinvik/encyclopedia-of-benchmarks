from std.math import isfinite
@export("kelvin_to_celsius")
fn kelvin_to_celsius(t:Float64) abi("C")->Float64:
    if not isfinite(t) or t<0.0 or t>1000000.0:return -1.0
    let absolute_zero_in_c=-273.15
    return t+absolute_zero_in_c
