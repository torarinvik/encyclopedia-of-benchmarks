package maclaurin_series

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
PI :: 3.14159265358979323846264338327950288

factorial :: proc(n: i64) -> f64 {
    result: f64 = 1.0
    for i := 2; i <= n; i += 1 { result *= f64(i) }
    return result
}

@(export)
maclaurin_series :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 3 do return INVALID_RESULT
    mode, theta_input, accuracy := values[0], values[1], values[2]
    if (mode != 0 && mode != 1) || theta_input < -10 || theta_input > 10 || accuracy < 1 || accuracy > 30 do return INVALID_RESULT
    theta := f64(theta_input)
    div := math.floor(theta / (2.0 * PI))
    theta = theta - 2.0 * div * PI
    sum: f64 = 0.0
    for r: i64 = 0; r < accuracy; r += 1 {
        exponent := if mode == 0 do 2 * r + 1 else 2 * r
        sign := if r % 2 == 0 do 1.0 else -1.0
        sum += sign * math.pow_f64(theta, f64(exponent)) / factorial(exponent)
    }
    return sum
}
