module gaussian

import math

const invalid_result = -1.0e300
const pi_value = 3.14159265358979323846264338327950288

@[export: 'gaussian']
pub fn gaussian(values &i64, length usize) f64 {
    if length != 3 { return invalid_result }
    x := unsafe { values[0] }
    mu := unsafe { values[1] }
    sigma := unsafe { values[2] }
    if x < -100 || x > 100 || mu < -100 || mu > 100 || sigma < 1 || sigma > 100 { return invalid_result }
    difference := x - mu
    sigma_squared := sigma * sigma
    normalization := 1.0 / math.sqrt(2.0 * pi_value * f64(sigma_squared))
    exponent := -f64(difference * difference) / f64(2 * sigma_squared)
    return normalization * math.exp(exponent)
}
