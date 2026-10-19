from std.math import isfinite

@export("fast_inverse_sqrt_cpp")
fn fast_inverse_sqrt_cpp(value: Float64) abi("C") -> Float64:
    if not isfinite(value) or value < 1.0e-6 or value > 1.0e6: return -1.0
    var y = value
    let x2 = y * 0.5
    var bits = bitcast[UInt64](y)
    bits = 0x5fe6eb50c7b537a9 - (bits >> 1)
    y = bitcast[Float64](bits)
    y = y * (1.5 - (x2 * y * y))
    y = y * (1.5 - (x2 * y * y))
    return y
