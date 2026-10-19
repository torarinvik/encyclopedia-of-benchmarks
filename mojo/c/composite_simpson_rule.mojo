from std.math import exp, floor, log, pow, sqrt

fn simpson_sample(function_id: Int64, x: Float64) -> Float64:
    if function_id == 0: return sqrt(x) + log(x)
    if function_id == 1: return exp(-x) * (4.0 - pow(x, 2.0))
    if function_id == 2: return sqrt(2.0 * pow(x, 3.0) + 3.0)
    return x + log(2.0 * x + 1.0)

@export("composite_simpson_rule")
fn composite_simpson_rule(intervals_input: Float64, function_id_input: Float64) abi("C") -> Float64:
    if intervals_input != intervals_input or function_id_input != function_id_input or intervals_input < 2.0 or intervals_input > 128.0 or floor(intervals_input) != intervals_input or function_id_input < 0.0 or function_id_input > 3.0 or floor(function_id_input) != function_id_input: return -1.0
    let intervals = Int64(intervals_input)
    if intervals % 2 != 0: return -1.0
    let function_id = Int64(function_id_input)
    let h = 2.0 / Float64(intervals)
    var x: Float64 = 1.0
    var sum: Float64 = 0.0
    for i in range(intervals + 1):
        let y = simpson_sample(function_id, x)
        let weight = 1.0 if i == 0 or i == intervals else (4.0 if i % 2 == 1 else 2.0)
        sum += weight * y
        x += h
    return sum * (h / 3.0)
