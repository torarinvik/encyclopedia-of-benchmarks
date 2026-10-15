module quadratic_roots

import math

const coefficient_limit = i64(1_000_000)

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'quadratic_roots']
pub fn quadratic_roots(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != 3 { return -1 }
	ai, bi, ci := values[0], values[1], values[2]
	if ai == 0 || ai < -coefficient_limit || ai > coefficient_limit ||
		bi < -coefficient_limit || bi > coefficient_limit ||
		ci < -coefficient_limit || ci > coefficient_limit { return -1 }

	a, b, c := f64(ai), f64(bi), f64(ci)
	discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0 { return 0 }

	if discriminant == 0.0 {
		if unsafe { output == nil } || output_capacity < 8 { return -2 }
		write_f64_le(mut output, 0, -b / (2.0 * a))
		return 1
	}

	if unsafe { output == nil } || output_capacity < 16 { return -2 }
	square_root := math.sqrt(discriminant)
	write_f64_le(mut output, 0, (-b + square_root) / (2.0 * a))
	write_f64_le(mut output, 8, (-b - square_root) / (2.0 * a))
	return 2
}

