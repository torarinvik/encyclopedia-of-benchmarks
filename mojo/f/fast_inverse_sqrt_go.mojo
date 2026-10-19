from std.math import isfinite

fn go_inverse_step(x2: Float32, y: Float32) -> Float32:
    let product1 = Float32(x2 * y)
    let product2 = Float32(product1 * y)
    let correction = Float32(Float32(1.5) - product2)
    return Float32(y * correction)

@export("fast_inverse_sqrt_go")
fn fast_inverse_sqrt_go(value: Float64) abi("C") -> Float64:
    if not isfinite(value) or value < 1.0e-6 or value > 1.0e6: return -1.0
    let number = Float32(value)
    let x2 = Float32(number * Float32(0.5))
    var bits = bitcast[UInt32](number)
    bits = 0x5f3759df - (bits >> 1)
    var y = bitcast[Float32](bits)
    y = go_inverse_step(x2, y)
    y = go_inverse_step(x2, y)
    return Float64(y)
