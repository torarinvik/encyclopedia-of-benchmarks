from std.math import floor, pow, sqrt

@export("fibonacci_number_golden_ration")
fn fibonacci_number_golden_ration(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 70: return -1
    if input <= 1: return input
    let root5 = sqrt(5.0)
    let phi = (1.0 + root5) / 2.0
    let psi = (1.0 - root5) / 2.0
    let result = (pow(phi, Float64(input)) - pow(psi, Float64(input))) / root5
    return Int64(floor(result + 0.5))
