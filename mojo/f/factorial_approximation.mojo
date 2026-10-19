from std.math import pow, sqrt

@export("factorial_approximation")
fn factorial_approximation(x: Float64) abi("C") -> Float64:
    if not (x >= 0.0 and x <= 170.0): return -1.0
    let correction = 8.0 * pow(x, 3.0) + 4.0 * pow(x, 2.0) + x + 1.0 / 30.0
    return sqrt(3.141592653589793) * pow(x / 2.718281828459045, x) * pow(correction, 1.0 / 6.0)
