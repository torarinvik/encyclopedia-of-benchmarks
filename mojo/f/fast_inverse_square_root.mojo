from std.math import isfinite

@export("fast_inverse_square_root")
fn fast_inverse_square_root(value: Float64) abi("C") -> Float64:
    if not isfinite(value) or value < 1.0e-6 or value > 1.0e6: return -1.0
    let seed_input = Float32(value)
    var bits = bitcast[Int32](seed_input)
    bits = 0x5f3759df - (bits >> 1)
    let seed = bitcast[Float32](bits)
    let y = Float64(seed)
    return y * (1.5 - 0.5 * value * y * y)
