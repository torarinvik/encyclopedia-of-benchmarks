module fast_inverse_sqrt_go

import math

const min_value = 1e-6
const max_value = 1e6

fn newton_step(x2 f32, y f32) f32 {
	product1 := x2 * y
	product2 := product1 * y
	correction := f32(1.5) - product2
	return y * correction
}

@[export: 'fast_inverse_sqrt_go']
pub fn fast_inverse_sqrt_go(value f64) f64 {
	if !math.is_finite(value) || value < min_value || value > max_value { return -1.0 }
	number := f32(value)
	x2 := number * f32(0.5)
	bits := math.f32_bits(number)
	seed_bits := u32(0x5f3759df) - (bits >> 1)
	mut y := math.f32_from_bits(seed_bits)
	y = newton_step(x2, y)
	y = newton_step(x2, y)
	return f64(y)
}
