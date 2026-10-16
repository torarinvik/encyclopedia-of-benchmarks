package fast_inverse_sqrt_cpp

import "core:math"

MIN_VALUE :: 1e-6
MAX_VALUE :: 1e6

@(export)
fast_inverse_sqrt_cpp :: proc "c" (value: f64) -> f64 {
    if math.is_nan(value) || value < MIN_VALUE || value > MAX_VALUE do return -1.0
    y := value
    x2 := y * 0.5
    bits := transmute(i64)y
    bits = i64(0x5fe6eb50c7b537a9) - (bits >> 1)
    y = transmute(f64)bits
    y = y * (1.5 - (x2 * y * y))
    y = y * (1.5 - (x2 * y * y))
    return y
}
