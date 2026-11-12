package split_operator_imaginary_time

import "core:c"
import "core:math"

MAX_N :: 64
MAX_STEPS :: 8
MAX_INPUT_LENGTH :: 2 + 4 * MAX_N
TAU :: 6.28318530717958647692528676655900577

bounded_integer :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	return math.is_finite(value) && math.trunc(value) == value && value >= minimum && value <= maximum
}

fft :: proc "contextless" (real, imag: [^]f64, n: int, inverse: bool) {
	reverse := 0
	for position := 1; position < n; position += 1 {
		bit := n >> 1
		for bit != 0 && (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			temporary := real[position]; real[position] = real[reverse]; real[reverse] = temporary
			temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary
		}
	}
	for block := 2; block <= n; block *= 2 {
		direction := -1.0
		if inverse do direction = 1.0
		angle := direction * TAU / f64(block)
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
	}
	if inverse {
		for i := 0; i < n; i += 1 { real[i] /= f64(n); imag[i] /= f64(n) }
	}
}

normalize :: proc "contextless" (real, imag: [^]f64, n: int) {
	norm_squared := f64(0)
	for i := 0; i < n; i += 1 do norm_squared += real[i] * real[i] + imag[i] * imag[i]
	norm := math.sqrt(norm_squared)
	for i := 0; i < n; i += 1 { real[i] /= norm; imag[i] /= norm }
}

@(export)
split_operator_imaginary_time :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if !bounded_integer(input[0], 2.0, f64(MAX_N)) || !bounded_integer(input[1], 0.0, f64(MAX_STEPS)) do return -1
	n := int(input[0])
	steps := int(input[1])
	if (n & (n - 1)) != 0 || length != c.size_t(2 + 4 * n) do return -1
	momentum_start := 2 + n
	state_start := 2 + 2 * n
	norm_squared := f64(0)
	for i := 0; i < n; i += 1 {
		position, momentum := input[2 + i], input[momentum_start + i]
		real_value, imag_value := input[state_start + 2 * i], input[state_start + 2 * i + 1]
		if !math.is_finite(position) || position < 0.25 || position > 1.0 ||
			!math.is_finite(momentum) || momentum < 0.25 || momentum > 1.0 ||
			!math.is_finite(real_value) || real_value < -1.0 || real_value > 1.0 ||
			!math.is_finite(imag_value) || imag_value < -1.0 || imag_value > 1.0 do return -1
		norm_squared += real_value * real_value + imag_value * imag_value
	}
	if !(norm_squared > 0.0) do return -1
	output_count := 2 * n
	if output == nil || capacity < c.size_t(output_count) do return -2

	real: [MAX_N]f64
	imag: [MAX_N]f64
	for i := 0; i < n; i += 1 { real[i] = input[state_start + 2 * i]; imag[i] = input[state_start + 2 * i + 1] }
	normalize(&real[0], &imag[0], n)
	for _step := 0; _step < steps; _step += 1 {
		for i := 0; i < n; i += 1 { real[i] *= input[2 + i]; imag[i] *= input[2 + i] }
		fft(&real[0], &imag[0], n, false)
		for i := 0; i < n; i += 1 { real[i] *= input[momentum_start + i]; imag[i] *= input[momentum_start + i] }
		fft(&real[0], &imag[0], n, true)
		for i := 0; i < n; i += 1 { real[i] *= input[2 + i]; imag[i] *= input[2 + i] }
		normalize(&real[0], &imag[0], n)
	}
	for i := 0; i < n; i += 1 { output[2 * i] = real[i]; output[2 * i + 1] = imag[i] }
	return i64(output_count)
}
