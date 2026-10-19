from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor, pow

fn maclaurin_series_factorial(n: Int) -> Float64:
    var f = 1.0
    for i in range(2, n + 1): f *= Float64(i)
    return f

@export("maclaurin_series")
fn maclaurin_series(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 3: return -1.0e300
    let mode = v[0]; let theta_input = v[1]; let accuracy = v[2]
    if (mode != 0 and mode != 1) or theta_input < -10 or theta_input > 10 or accuracy < 1 or accuracy > 30: return -1.0e300
    let pi = 3.14159265358979323846264338327950288
    let theta0 = Float64(theta_input); let div = floor(theta0 / (2.0 * pi)); let theta = theta0 - 2.0 * div * pi
    var sum = 0.0
    for r in range(Int(accuracy)):
        let exponent = 2 * r + (1 if mode == 0 else 0)
        let sign = 1.0 if r % 2 == 0 else -1.0
        sum += sign * pow(theta, Float64(exponent)) / maclaurin_series_factorial(exponent)
    return sum
