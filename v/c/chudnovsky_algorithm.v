module chudnovsky_algorithm

const max_precision = 12

fn sqrt_10005() f64 {
	mut root := 100.0
	for _ in 0 .. 8 { root = 0.5 * (root + 10005.0 / root) }
	return root
}

@[export: 'chudnovsky_algorithm']
pub fn chudnovsky_algorithm(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length != 1 || values[0] < 1 || values[0] > max_precision { return -1 }
		precision := int(values[0])
		output_length := if precision == 1 { 0 } else { precision }
		if capacity < usize(output_length) || (output_length > 0 && output == nil) { return -2 }
		if precision == 1 { return 0 }

		pi := (426880.0 * sqrt_10005()) / 13591409.0
		mut fraction := pi - 3.0
		output[0] = 51
		output[1] = 46
		for digit in 0 .. precision - 2 {
			fraction *= 10.0
			next_digit := int(fraction)
			output[2 + digit] = u8(48 + next_digit)
			fraction -= f64(next_digit)
		}
		return i64(output_length)
	}
}
