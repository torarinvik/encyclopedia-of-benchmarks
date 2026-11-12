module split_operator_imaginary_time

import math

const max_n = 64
const max_steps = 8
const max_input_length = 2 + 4 * max_n
const tau = 6.28318530717958647692528676655900577

fn bounded_integer(value f64, minimum f64, maximum f64) bool {
	return math.is_finite(value) && value >= minimum && value <= maximum && math.trunc(value) == value
}

fn fft(mut real []f64, mut imag []f64, n int, inverse bool) {
	mut reverse := 0
	for position in 1 .. n {
		mut bit := n >> 1
		for bit != 0 && (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			real[position], real[reverse] = real[reverse], real[position]
			imag[position], imag[reverse] = imag[reverse], imag[position]
		}
	}
	mut block := 2
	for block <= n {
		direction := if inverse { 1.0 } else { -1.0 }
		angle := direction * tau / f64(block)
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
		for i in 0 .. n { real[i] /= f64(n); imag[i] /= f64(n) }
	}
}

fn normalize(mut real []f64, mut imag []f64, n int) {
	mut norm_squared := 0.0
	for i in 0 .. n { norm_squared += real[i] * real[i] + imag[i] * imag[i] }
	norm := math.sqrt(norm_squared)
	for i in 0 .. n { real[i] /= norm; imag[i] /= norm }
}

@[export: 'split_operator_imaginary_time']
pub fn split_operator_imaginary_time(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if !bounded_integer(input[0], 2.0, f64(max_n)) || !bounded_integer(input[1], 0.0, f64(max_steps)) { return -1 }
		n := int(input[0])
		steps := int(input[1])
		if (n & (n - 1)) != 0 || length != usize(2 + 4 * n) { return -1 }
		momentum_start := 2 + n
		state_start := 2 + 2 * n
		mut norm_squared := 0.0
		for i in 0 .. n {
			position := input[2 + i]
			momentum := input[momentum_start + i]
			real_value := input[state_start + 2 * i]
			imag_value := input[state_start + 2 * i + 1]
			if !math.is_finite(position) || position < 0.25 || position > 1.0 ||
				!math.is_finite(momentum) || momentum < 0.25 || momentum > 1.0 ||
				!math.is_finite(real_value) || real_value < -1.0 || real_value > 1.0 ||
				!math.is_finite(imag_value) || imag_value < -1.0 || imag_value > 1.0 { return -1 }
			norm_squared += real_value * real_value + imag_value * imag_value
		}
		if !(norm_squared > 0.0) { return -1 }
		output_count := 2 * n
		if output == nil || capacity < usize(output_count) { return -2 }

		mut real := []f64{len: max_n}
		mut imag := []f64{len: max_n}
		for i in 0 .. n {
			real[i] = input[state_start + 2 * i]
			imag[i] = input[state_start + 2 * i + 1]
		}
		normalize(mut real, mut imag, n)
		for _ in 0 .. steps {
			for i in 0 .. n { real[i] *= input[2 + i]; imag[i] *= input[2 + i] }
			fft(mut real, mut imag, n, false)
			for i in 0 .. n { real[i] *= input[momentum_start + i]; imag[i] *= input[momentum_start + i] }
			fft(mut real, mut imag, n, true)
			for i in 0 .. n { real[i] *= input[2 + i]; imag[i] *= input[2 + i] }
			normalize(mut real, mut imag, n)
		}
		for i in 0 .. n { output[2 * i] = real[i]; output[2 * i + 1] = imag[i] }
		return i64(output_count)
	}
}
