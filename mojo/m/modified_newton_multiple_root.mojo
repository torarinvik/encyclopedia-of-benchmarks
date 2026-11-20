from std.math import floor, isfinite

@export("modified_newton_multiple_root")
fn modified_newton_multiple_root(initial_x: Float64, iteration_count: Float64) abi("C") -> Float64:
    if not isfinite(initial_x) or not isfinite(iteration_count):
        return -1.0
    if initial_x < 1.0 or initial_x > 2.0 or iteration_count < 0.0 or iteration_count > 8.0:
        return -1.0
    if floor(iteration_count) != iteration_count:
        return -1.0

    var x = initial_x
    for _ in range(Int(iteration_count)):
        if x == 1.0:
            break
        let offset = x - 1.0
        let value = offset * offset * (x + 2.0)
        let derivative = 3.0 * offset * (x + 1.0)
        if derivative == 0.0 or not isfinite(derivative):
            return -1.0
        x -= 2.0 * (value / derivative)
        if not isfinite(x) or x < 1.0 or x > 2.0:
            return -1.0
    return x
