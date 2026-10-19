from std.math import pow, sqrt

@export("fibonacci_formula")
fn fibonacci_formula(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 35: return -1
    let root5 = sqrt(5.0)
    let phi = (1.0 + root5) / 2.0
    let psi = (1.0 - root5) / 2.0
    let nn = Float64(input + 1)
    let value = (1.0 / root5 * pow(phi, nn)) - (1.0 / root5 * pow(psi, nn))
    return Int64(Float32(value))
