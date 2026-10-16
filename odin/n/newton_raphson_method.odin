package newton_raphson_method

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

equation :: proc "contextless"(x: f64) -> f64 { return math.pow_f64(x, 3.0) - (4.0 * x) - 9.0 }
derivative :: proc "contextless"(x: f64) -> f64 { return 3.0 * math.pow_f64(x, 2.0) - 4.0 }
absolute_f64 :: proc "contextless"(x: f64) -> f64 { if x < 0 do return -x; return x }

@(export)
newton_raphson_method :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 do return INVALID_RESULT
    initial_milli, iteration_limit := values[0], values[1]
    if initial_milli < 2000 || initial_milli > 4000 || iteration_limit < 1 || iteration_limit > 32 do return INVALID_RESULT
    c_value := f64(initial_milli) / 1000.0
    z := c_value
    for iteration := i64(0); iteration < iteration_limit; iteration += 1 {
        m := equation(c_value)
        n := derivative(c_value)
        z = c_value - (m / n)
        c_value = z
        if absolute_f64(m) < 1e-10 do break
    }
    return z
}
