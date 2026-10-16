package convolution_fft

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 131
PI :: 3.14159265358979323846264338327950288

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

transform :: proc "contextless" (real, imag: [^]f64, n: int, inverse: bool) {
	reverse := 0
	for position := 1; position < n; position += 1 {
		bit := n >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			temporary := real[position]; real[position] = real[reverse]; real[reverse] = temporary
			temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary
		}
	}
	block := 2
	for block <= n {
		direction := 1.0
		if inverse do direction = -1.0
		angle := -2.0 * PI / f64(block) * direction
		step_real, step_imag := math.cos(angle), math.sin(angle)
		for start := 0; start < n; start += block {
			weight_real, weight_imag := 1.0, 0.0
			for offset := 0; offset < block / 2; offset += 1 {
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
		}
		block *= 2
	}
	if inverse {
		for index := 0; index < n; index += 1 { real[index] /= f64(n); imag[index] /= f64(n) }
	}
}

@(export)
convolution_fft :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	raw_a, raw_b := input[0], input[1]
	if raw_a < 1 || raw_a > 64 || raw_b < 1 || raw_b > 64 do return -1
	a_count, b_count := int(raw_a), int(raw_b)
	if length != c.size_t(2 + a_count + b_count) do return -1
	for index := 0; index < a_count + b_count; index += 1 {
		if input[index+2] < -64 || input[index+2] > 64 do return -1
	}
	result_count := a_count + b_count - 1
	byte_count := result_count * 16
	if output == nil || capacity < c.size_t(byte_count) do return -2
	fft_length := 1
	for fft_length < result_count { fft_length *= 2 }
	var a_real, a_imag, b_real, b_imag, product_real, product_imag: [128]f64
	for index := 0; index < fft_length; index += 1 {
		a_real[index], a_imag[index], b_real[index], b_imag[index] = 0, 0, 0, 0
		product_real[index], product_imag[index] = 0, 0
	}
	for index := 0; index < a_count; index += 1 { a_real[index] = f64(input[index+2]) / 16.0 }
	for index := 0; index < b_count; index += 1 { b_real[index] = f64(input[a_count+index+2]) / 16.0 }
	transform(&a_real[0], &a_imag[0], fft_length, false)
	transform(&b_real[0], &b_imag[0], fft_length, false)
	for index := 0; index < fft_length; index += 1 {
		product_real[index] = a_real[index]*b_real[index] - a_imag[index]*b_imag[index]
		product_imag[index] = a_real[index]*b_imag[index] + a_imag[index]*b_real[index]
	}
	transform(&product_real[0], &product_imag[0], fft_length, true)
	for index := 0; index < result_count; index += 1 {
		write_f64_le(output, index*16, product_real[index])
		write_f64_le(output, index*16+8, product_imag[index])
	}
	return i64(byte_count)
}
