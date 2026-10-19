from std.math import sqrt

@export("arithmetic_geometric_mean")
fn arithmetic_geometric_mean(first: Float64, second: Float64) abi("C") -> Float64:
    if first != first or second != second or first < 0.0 or second < 0.0 or first > 1000000.0 or second > 1000000.0:
        return -1.0
    if first == second:
        return first
    var arithmetic = first
    var geometric = second
    var previous = arithmetic
    while True:
        previous = arithmetic
        let next_arithmetic = (arithmetic + geometric) / 2.0
        let next_geometric = sqrt(arithmetic * geometric)
        arithmetic = next_arithmetic
        geometric = next_geometric
        if arithmetic == previous:
            break
    return arithmetic
