module npb_ft_3d_spectral_step

import math

const max_points = 64
const max_steps = 6
const checksum_terms = 64
const tau = 6.28318530717958647692528676655900577
const alpha = 0.000001

fn fft_line(mut real []f64, mut imag []f64, n int, inverse bool) {
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

fn line_index(axis int, a int, b int, p int, n int) int {
	if axis == 0 { return (p * n + a) * n + b }
	if axis == 1 { return (a * n + p) * n + b }
	return (a * n + b) * n + p
}

fn axis_transform(mut real []f64, mut imag []f64, n int, axis int, inverse bool) {
	mut line_real := []f64{len: 4}
	mut line_imag := []f64{len: 4}
	for a in 0 .. n {
		for b in 0 .. n {
			for p in 0 .. n {
				index := line_index(axis, a, b, p, n)
				line_real[p], line_imag[p] = real[index], imag[index]
			}
			fft_line(mut line_real, mut line_imag, n, inverse)
			for p in 0 .. n {
				index := line_index(axis, a, b, p, n)
				real[index], imag[index] = line_real[p], line_imag[p]
			}
		}
	}
}

fn transform3d(mut real []f64, mut imag []f64, n int, inverse bool) {
	axis_transform(mut real, mut imag, n, 2, inverse)
	axis_transform(mut real, mut imag, n, 1, inverse)
	axis_transform(mut real, mut imag, n, 0, inverse)
}

fn signed_frequency(index int, n int) int {
	return if index <= n / 2 { index } else { index - n }
}

@[export: 'npb_ft_3d_spectral_step']
pub fn npb_ft_3d_spectral_step(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 130 { return -1 }
	unsafe {
		if input[0] != 2.0 && input[0] != 4.0 { return -1 }
		if !math.is_finite(input[1]) || input[1] < 1.0 || input[1] > f64(max_steps) || math.trunc(input[1]) != input[1] { return -1 }
		n, steps := int(input[0]), int(input[1])
		volume := n * n * n
		if length != usize(2 + 2 * volume) { return -1 }
		for i in 2 .. int(length) {
			if !math.is_finite(input[i]) || input[i] < -1.0 || input[i] > 1.0 { return -1 }
		}
		needed := 2 * steps
		if unsafe { output == nil } || capacity < usize(needed) { return -2 }
		mut spectrum_real := []f64{len: max_points}
		mut spectrum_imag := []f64{len: max_points}
		mut work_real := []f64{len: max_points}
		mut work_imag := []f64{len: max_points}
		for i in 0 .. volume { spectrum_real[i], spectrum_imag[i] = input[2 + 2 * i], input[2 + 2 * i + 1] }
		transform3d(mut spectrum_real, mut spectrum_imag, n, false)
		for step in 1 .. steps + 1 {
			for x in 0 .. n {
				for y in 0 .. n {
					for z in 0 .. n {
						index := (x * n + y) * n + z
						kx, ky, kz := signed_frequency(x, n), signed_frequency(y, n), signed_frequency(z, n)
						radius_squared := f64(kx * kx + ky * ky + kz * kz)
						factor := math.exp(-39.47841760435743447533796399950460 * alpha * f64(step) * radius_squared)
						work_real[index], work_imag[index] = spectrum_real[index] * factor, spectrum_imag[index] * factor
					}
				}
			}
			transform3d(mut work_real, mut work_imag, n, true)
			mut sum_real, mut sum_imag := 0.0, 0.0
			for j in 1 .. checksum_terms + 1 {
				x, y, z := (j - 1) % n, (3 * j - 1) % n, (5 * j - 1) % n
				index := (x * n + y) * n + z
				sum_real += work_real[index]
				sum_imag += work_imag[index]
			}
			output[2 * (step - 1)] = sum_real / f64(volume)
			output[2 * (step - 1) + 1] = sum_imag / f64(volume)
		}
		return i64(needed)
	}
}
