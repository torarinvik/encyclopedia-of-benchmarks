package gaussian

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
PI :: 3.14159265358979323846264338327950288

@(export)
gaussian :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 3 do return INVALID_RESULT
    x, mu, sigma := values[0], values[1], values[2]
    if x < -100 || x > 100 || mu < -100 || mu > 100 || sigma < 1 || sigma > 100 do return INVALID_RESULT
    difference := x - mu
    sigma_squared := sigma * sigma
    normalization := 1.0 / math.sqrt_f64(2.0 * PI * f64(sigma_squared))
    exponent := -f64(difference * difference) / f64(2 * sigma_squared)
    return normalization * math.exp_f64(exponent)
}
