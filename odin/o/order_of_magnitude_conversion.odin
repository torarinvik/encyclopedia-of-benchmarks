package order_of_magnitude_conversion

import "core:math"

MAX_VALUE :: 1e100

unit_exponent :: proc(code: f64) -> i32 {
    if code == 0.0 do return 0
    if code == 1.0 do return 3
    if code == 2.0 do return 6
    if code == 3.0 do return 9
    if code == 4.0 do return 12
    if code == 5.0 do return 15
    if code == 6.0 do return 18
    if code == 7.0 do return 21
    if code == 8.0 do return 24
    return -1
}

// Preserve the source formula and operation order: value * 10^(from - to).
@(export)
order_of_magnitude_conversion :: proc "c" (value, from_unit_code, to_unit_code: f64) -> f64 {
    if math.is_nan(value) || value < -MAX_VALUE || value > MAX_VALUE do return -1.0
    from_exp := unit_exponent(from_unit_code)
    to_exp := unit_exponent(to_unit_code)
    if from_exp < 0 || to_exp < 0 do return -1.0
    return value * math.pow_f64(10.0, f64(from_exp - to_exp))
}
