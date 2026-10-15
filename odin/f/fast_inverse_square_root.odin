package fast_inverse_square_root

import "core:math"

MIN_VALUE :: 1e-6
MAX_VALUE :: 1e6

// Match PHP's float32 pack/unpack through binary32 bit reinterpretation.
@(export)
fast_inverse_square_root :: proc "c" (value: f64) -> f64 {
    if math.is_nan(value) || value < MIN_VALUE || value > MAX_VALUE do return -1.0
    seed_input := f32(value)
    bits := transmute(i32)seed_input
    seed_bits := i32(0x5f3759df) - (bits >> 1)
    seed := transmute(f32)seed_bits
    y := f64(seed)
    return y * (1.5 - 0.5 * value * y * y)
}
