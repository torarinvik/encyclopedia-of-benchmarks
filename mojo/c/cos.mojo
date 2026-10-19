from std.math import floor

@export("cos")
fn cos_approx(x_input: Float64) abi("C") -> Float64:
    if not (x_input >= -1000000.0 and x_input <= 1000000.0): return -1.0
    var x = x_input
    let tp = 1.0 / (2.0 * 3.141592653589793)
    x *= tp
    x -= 0.25 + floor(x + 0.25)
    let ax = x if x >= 0.0 else -x
    x *= 16.0 * (ax - 0.5)
    let abs_x = x if x >= 0.0 else -x
    x += 0.225 * x * (abs_x - 1.0)
    return x
