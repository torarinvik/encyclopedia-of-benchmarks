package sqrt

import "core:math"

MIN_VALUE :: 1e-6
MAX_VALUE :: 1e6

newton_step :: proc(x2, y: f32) -> f32 {
    product1 := x2 * y
    product2 := product1 * y
    correction := f32(1.5) - product2
    return y * correction
}

// Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
@(export)
go_sqrt_f32 :: proc "c" (value: f64) -> f64 {
    if math.is_nan(value) || value < MIN_VALUE || value > MAX_VALUE do return -1.0
    number := f32(value)
    x2 := number * f32(0.5)
    bits := transmute(u32)number
    seed_bits := u32(0x5f3759df) - (bits >> 1)
    inverse_root := transmute(f32)seed_bits
    inverse_root = newton_step(x2, inverse_root)
    inverse_root = newton_step(x2, inverse_root)
    root := f32(1.0) / inverse_root
    return f64(root)
}
