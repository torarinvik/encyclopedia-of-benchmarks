module maclaurin_series

import math

const invalid_result = -1.0e300
const pi_value = 3.14159265358979323846264338327950288

fn factorial(n i64) f64 {
    mut result := 1.0
    for i := i64(2); i <= n; i++ { result *= f64(i) }
    return result
}

@[export: 'maclaurin_series']
pub fn maclaurin_series(values &i64, length usize) f64 {
    if length != 3 { return invalid_result }
    mode := unsafe { values[0] }
    theta_input := unsafe { values[1] }
    accuracy := unsafe { values[2] }
    if (mode != 0 && mode != 1) || theta_input < -10 || theta_input > 10 || accuracy < 1 || accuracy > 30 { return invalid_result }
    mut theta := f64(theta_input)
    div := math.floor(theta / (2.0 * pi_value))
    theta = theta - 2.0 * div * pi_value
    mut sum := 0.0
    for r := i64(0); r < accuracy; r++ {
        exponent := if mode == 0 { 2 * r + 1 } else { 2 * r }
        sign := if r % 2 == 0 { 1.0 } else { -1.0 }
        sum += sign * math.pow(theta, f64(exponent)) / factorial(exponent)
    }
    return sum
}
