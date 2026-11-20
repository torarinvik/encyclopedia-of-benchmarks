from std.math import floor, isfinite

@export("halley_root_finding")
fn halley_root_finding(initial_x: Float64, iteration_count: Float64) abi("C") -> Float64:
    if not isfinite(initial_x) or not isfinite(iteration_count):
        return -1.0
    if initial_x < 0.5 or initial_x > 2.0 or iteration_count < 0.0 or iteration_count > 8.0:
        return -1.0
    if floor(iteration_count) != iteration_count:
        return -1.0

    var x = initial_x
    for _ in range(Int(iteration_count)):
        let value = x * x * x - 2.0
        let first = 3.0 * x * x
        let second = 6.0 * x
        let denominator = 2.0 * first * first - value * second
        if denominator == 0.0 or not isfinite(denominator):
            return -1.0
        x -= (2.0 * value * first) / denominator
        if not isfinite(x):
            return -1.0
    return x
