module fast_inverse_square_root

import math

const min_value = 1e-6
const max_value = 1e6

// Match PHP's float32 pack/unpack through binary32 bit reinterpretation.
@[export: 'fast_inverse_square_root']
pub fn fast_inverse_square_root(value f64) f64 {
	if math.is_nan(value) || value < min_value || value > max_value { return -1.0 }
	seed_input := f32(value)
	bits := math.f32_bits(seed_input)
	seed_bits := u32(0x5f3759df) - (bits >> 1)
	seed := math.f32_from_bits(seed_bits)
	y := f64(seed)
	return y * (1.5 - 0.5 * value * y * y)
}
