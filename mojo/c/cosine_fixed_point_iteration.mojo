from std.math import cos, floor, isfinite

@export("cosine_fixed_point_iteration")
fn cosine_fixed_point_iteration(initial_input: Float64, source_n: Float64) abi("C") -> Float64:
    if not isfinite(initial_input) or not isfinite(source_n):
        return -1.0
    if initial_input < 0.0 or initial_input > 2.0 or source_n < 0.0 or source_n > 64.0:
        return -1.0
    if floor(source_n) != source_n:
        return -1.0

    var value = initial_input
    let updates = Int(source_n) + 1
    for _ in range(updates):
        value = 0.5 * (cos(value) + 2.0)
    return value
