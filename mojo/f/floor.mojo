from std.math import isfinite

@export("floor")
fn floor(value: Float64) abi("C") -> Float64:
    if not isfinite(value) or value < -1000000.0 or value > 1000000.0: return -1.0
    let whole = Int64(value)
    if value < Float64(whole): return Float64(whole - 1)
    return Float64(whole)
