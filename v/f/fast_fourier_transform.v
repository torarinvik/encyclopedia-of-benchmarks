module fast_fourier_transform

import math

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}
fn quantize(value f64) i64 {
	scaled := value * 1_000_000.0
	if scaled >= 0.0 { return i64(scaled + 0.5) }
	return i64(scaled - 0.5)
}
fn transform(mut real []f64, mut imag []f64) {
	n := real.len
	mut reverse := 0
	for position in 1 .. n {
		mut bit := n >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse { real[position], real[reverse] = real[reverse], real[position]; imag[position], imag[reverse] = imag[reverse], imag[position] }
	}
	mut block := 2
	for block <= n {
		angle := 6.283185307179586476925286766559 / f64(block)
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
}

@[export: 'fast_fourier_transform']
pub fn fast_fourier_transform(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 65 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_n := values[0]
		if raw_n < 1 || raw_n > 64 || (raw_n & (raw_n - 1)) != 0 { return -1 }
		n := int(raw_n)
		if length != usize(n + 1) { return -1 }
		for index in 0 .. n { if values[index + 1] < -1000 || values[index + 1] > 1000 { return -1 } }
		byte_count := 16 * n
		if output_capacity < usize(byte_count) || output == nil { return -2 }
		mut real := []f64{len: n, init: 0.0}
		mut imag := []f64{len: n, init: 0.0}
		for index in 0 .. n { real[index] = f64(values[index + 1]) }
		transform(mut real, mut imag)
		for index in 0 .. n {
			store_i64_le(mut output, index * 16, quantize(real[index]))
			store_i64_le(mut output, index * 16 + 8, quantize(imag[index]))
		}
		return i64(byte_count)
	}
}
