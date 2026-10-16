module sqrt

import math

const min_value = 1e-6
const max_value = 1e6

fn newton_step(x2 f32, y f32) f32 {
	product1 := x2 * y
	product2 := product1 * y
	correction := f32(1.5) - product2
	return y * correction
}

// Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
@[export: 'go_sqrt_f32']
pub fn go_sqrt_f32(value f64) f64 {
	if !math.is_finite(value) || value < min_value || value > max_value { return -1.0 }
	number := f32(value)
	x2 := number * f32(0.5)
	bits := math.f32_bits(number)
	seed_bits := u32(0x5f3759df) - (bits >> 1)
	mut inverse_root := math.f32_from_bits(seed_bits)
	inverse_root = newton_step(x2, inverse_root)
	inverse_root = newton_step(x2, inverse_root)
	root := f32(1.0) / inverse_root
	return f64(root)
}
