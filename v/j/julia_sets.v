module main

import math

fn put_f32_le(output &u8, offset int, value f32) {
	bits := math.f32_bits(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'julia_sets']
pub fn julia_sets(input &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(input) || length < 4 || length > 68 { return -1 }
	unsafe {
		iterations, cr_units, ci_units, count_value := input[0], input[1], input[2], input[3]
		if iterations < 0 || iterations > 8 || count_value < 0 || count_value > 32 { return -1 }
		if cr_units < -128 || cr_units > 128 || ci_units < -128 || ci_units > 128 { return -1 }
		count := int(count_value)
		if length != usize(4 + 2 * count) { return -1 }
		for index := 0; index < 2 * count; index++ {
			if input[4 + index] < -128 || input[4 + index] > 128 { return -1 }
		}
		needed := 8 * count
		if isnil(output) || capacity < usize(needed) { return -2 }
		cr := f32(cr_units) / 16.0
		ci := f32(ci_units) / 16.0
		mut computed := [64]f32{}
		for point := 0; point < count; point++ {
			mut real := f32(input[4 + 2 * point]) / 16.0
			mut imag := f32(input[5 + 2 * point]) / 16.0
			for _ in 0 .. int(iterations) {
				real_square := real * real
				imag_square := imag * imag
				real_imag := real * imag
				imag_real := imag * real
				next_real := (real_square - imag_square) + cr
				next_imag := (real_imag + imag_real) + ci
				if !math.is_finite(f64(next_real)) || !math.is_finite(f64(next_imag)) { return -1 }
				real = next_real
				imag = next_imag
			}
			computed[2 * point] = real
			computed[2 * point + 1] = imag
		}
		for component := 0; component < 2 * count; component++ {
			put_f32_le(output, component * 4, computed[component])
		}
		return i64(needed)
	}
}
