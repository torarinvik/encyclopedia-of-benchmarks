package composite_simpson_rule

import "core:math"

INVALID_RESULT :: -1.0
MAX_INTERVALS :: 128

sample :: proc(function_id: i32, x: f64) -> f64 {
    switch function_id {
    case 0: return math.sqrt_f64(x) + math.log_f64(x)
    case 1: return math.exp_f64(-x) * (4.0 - math.pow_f64(x, 2.0))
    case 2: return math.sqrt_f64(2.0 * math.pow_f64(x, 3.0) + 3.0)
    case: return x + math.log_f64(2.0 * x + 1.0)
    }
}

@(export)
composite_simpson_rule :: proc "c" (intervals_input, function_id_input: f64) -> f64 {
    if math.is_nan_f64(intervals_input) || math.is_nan_f64(function_id_input) ||
        intervals_input < 2.0 || intervals_input > f64(MAX_INTERVALS) ||
        function_id_input < 0.0 || function_id_input > 3.0 ||
        f64(i32(intervals_input)) != intervals_input || f64(i32(function_id_input)) != function_id_input {
        return INVALID_RESULT
    }
    intervals := i32(intervals_input)
    if intervals % 2 != 0 do return INVALID_RESULT
    function_id := i32(function_id_input)
    h := 2.0 / f64(intervals)
    x := 1.0
    sum := 0.0
    for i := 0; i <= intervals; i += 1 {
        y := sample(function_id, x)
        weight := 1.0
        if i != 0 && i != intervals {
            weight = if i % 2 == 1 { 4.0 } else { 2.0 }
        }
        sum += weight * y
        x += h
    }
    return sum * (h / 3.0)
}
