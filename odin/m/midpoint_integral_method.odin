package midpoint_integral_method

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

integrand :: proc(function_id: i64, x: f64) -> f64 {
    switch function_id {
    case 0: return math.sqrt_f64(x) + math.log_f64(x)
    case 1: return math.exp_f64(-x) * (4.0 - math.pow_f64(x, 2.0))
    case 2: return math.sqrt_f64(2.0 * math.pow_f64(x, 3.0) + 3.0)
    case 3: return x + math.log_f64(2.0 * x + 1.0)
    }
    return INVALID_RESULT
}

@(export)
midpoint_integral_method :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 4 do return INVALID_RESULT
    function_id, intervals, a_milli, b_milli := values[0], values[1], values[2], values[3]
    if function_id < 0 || function_id > 3 || intervals < 2 || intervals > 64 || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000 do return INVALID_RESULT
    a := f64(a_milli) / 1000.0
    b := f64(b_milli) / 1000.0
    h := (b - a) / f64(intervals)
    xi, total := a, f64(0.0)
    for index := i64(0); index < intervals; index += 1 {
        total += integrand(function_id, xi + h / 2.0)
        xi += h
    }
    return total * h
}
