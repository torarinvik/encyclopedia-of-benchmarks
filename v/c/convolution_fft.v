module convolution_fft

import math

const max_input_length = 131
const pi_value = 3.14159265358979323846264338327950288

fn write_f64_le(mut output &u8, offset usize, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn transform(mut real []f64, mut imag []f64, inverse bool) {
	n := real.len
	mut reverse := 0
	for position in 1 .. n {
		mut bit := n >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			real[position], real[reverse] = real[reverse], real[position]
			imag[position], imag[reverse] = imag[reverse], imag[position]
		}
	}
	mut block := 2
	for block <= n {
		direction := if inverse { -1.0 } else { 1.0 }
		angle := -2.0 * pi_value / f64(block) * direction
		step_real, step_imag := math.cos(angle), math.sin(angle)
		mut start := 0
		for start < n {
			mut weight_real, mut weight_imag := 1.0, 0.0
			for offset in 0 .. block / 2 {
				first, second := start + offset, start + offset + block / 2
				product_real := weight_real * real[second] - weight_imag * imag[second]
				product_imag := weight_real * imag[second] + weight_imag * real[second]
				first_real, first_imag := real[first], imag[first]
				real[first], imag[first] = first_real + product_real, first_imag + product_imag
				real[second], imag[second] = first_real - product_real, first_imag - product_imag
				next_real := weight_real * step_real - weight_imag * step_imag
				weight_imag = weight_real * step_imag + weight_imag * step_real
				weight_real = next_real
			}
			start += block
		}
		block *= 2
	}
	if inverse {
		for index in 0 .. n { real[index] /= f64(n); imag[index] /= f64(n) }
	}
}

@[export: 'convolution_fft']
pub fn convolution_fft(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		raw_a, raw_b := input[0], input[1]
		if raw_a < 1 || raw_a > 64 || raw_b < 1 || raw_b > 64 { return -1 }
		a_count, b_count := int(raw_a), int(raw_b)
		if length != usize(2 + a_count + b_count) { return -1 }
		for index in 0 .. a_count + b_count { if input[index + 2] < -64 || input[index + 2] > 64 { return -1 } }
		result_count := a_count + b_count - 1
		byte_count := result_count * 16
		if output == nil || capacity < usize(byte_count) { return -2 }
		mut fft_length := 1
		for fft_length < result_count { fft_length *= 2 }
		mut a_real := []f64{len: fft_length, init: 0.0}
		mut a_imag := []f64{len: fft_length, init: 0.0}
		mut b_real := []f64{len: fft_length, init: 0.0}
		mut b_imag := []f64{len: fft_length, init: 0.0}
		mut product_real := []f64{len: fft_length, init: 0.0}
		mut product_imag := []f64{len: fft_length, init: 0.0}
		for index in 0 .. a_count { a_real[index] = f64(input[index + 2]) / 16.0 }
		for index in 0 .. b_count { b_real[index] = f64(input[a_count + index + 2]) / 16.0 }
		transform(mut a_real, mut a_imag, false)
		transform(mut b_real, mut b_imag, false)
		for index in 0 .. fft_length {
			product_real[index] = a_real[index] * b_real[index] - a_imag[index] * b_imag[index]
			product_imag[index] = a_real[index] * b_imag[index] + a_imag[index] * b_real[index]
		}
		transform(mut product_real, mut product_imag, true)
		for index in 0 .. result_count {
			write_f64_le(mut output, usize(index * 16), product_real[index])
			write_f64_le(mut output, usize(index * 16 + 8), product_imag[index])
		}
		return i64(byte_count)
	}
}
