module shree_dharacharya_formula

import math

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'shree_dharacharya_formula']
pub fn shree_dharacharya_formula(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		for index in 0 .. 3 {
			if input[index] < -1000000 || input[index] > 1000000 { return -1 }
		}
		if input[0] == 0 { return -1 }
		a := f64(input[0])
		b := f64(input[1])
		c := f64(input[2])
		discriminant := b * b - 4.0 * a * c
		if discriminant < 0.0 { return -1 }
		if output == nil || capacity < 16 { return -2 }
		root := math.sqrt(discriminant)
		denominator := 2.0 * a
		first := (-b + root) / denominator
		second := (-b - root) / denominator
		write_f64_le(mut output, 0, first)
		write_f64_le(mut output, 8, second)
		return 16
	}
}
