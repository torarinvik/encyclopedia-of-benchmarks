package fast_inverse_sqrt_go

import "core:math"

MIN_VALUE :: 1e-6
MAX_VALUE :: 1e6

newton_step :: proc(x2, y: f32) -> f32 {
	product1 := x2 * y
	product2 := product1 * y
	correction := f32(1.5) - product2
	return y * correction
}

@(export)
fast_inverse_sqrt_go :: proc "c" (value: f64) -> f64 {
	if math.is_nan(value) || value < MIN_VALUE || value > MAX_VALUE do return -1.0
	number := f32(value)
	x2 := number * f32(0.5)
	bits := transmute(u32)number
	seed_bits := u32(0x5f3759df) - (bits >> 1)
	y := transmute(f32)seed_bits
	y = newton_step(x2, y)
	y = newton_step(x2, y)
	return f64(y)
}
