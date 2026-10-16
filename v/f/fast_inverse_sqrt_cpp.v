module fast_inverse_sqrt_cpp

import math

const min_value = 1e-6
const max_value = 1e6

@[export: 'fast_inverse_sqrt_cpp']
pub fn fast_inverse_sqrt_cpp(value f64) f64 {
	if math.is_nan(value) || value < min_value || value > max_value { return -1.0 }
	mut y := value
	x2 := y * 0.5
	bits := i64(math.f64_bits(y))
	seed_bits := i64(0x5fe6eb50c7b537a9) - (bits >> 1)
	y = math.f64_from_bits(u64(seed_bits))
	y = y * (1.5 - (x2 * y * y))
	y = y * (1.5 - (x2 * y * y))
	return y
}
