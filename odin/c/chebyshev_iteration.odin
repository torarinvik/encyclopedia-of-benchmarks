package chebyshev_iteration

import "core:c"
import "core:math"

MAX_DIMENSION :: 8
MAX_MATRIX_MICRO :: i64(1_000_000_000)
MAX_VECTOR_MICRO :: i64(1_000_000_000)
MAX_SPECTRAL_MICRO :: i64(1_000_000_000)
MAX_ITERATIONS :: i64(1000)

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(byte * 8)) }
}

@(export)
chebyshev_iteration :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 1 + MAX_DIMENSION * MAX_DIMENSION + 2 * MAX_DIMENSION + 4 do return -1
	if values[0] < 1 || values[0] > MAX_DIMENSION do return -1
	n := int(values[0])
	if length != c.size_t(1 + n * n + 2 * n + 4) do return -1
	matrix_end := 1 + n * n
	vector_end := matrix_end + 2 * n
	a_values: [MAX_DIMENSION * MAX_DIMENSION]f64 = {}
	b: [MAX_DIMENSION]f64 = {}
	x: [MAX_DIMENSION]f64 = {}
	residual: [MAX_DIMENSION]f64 = {}
	direction: [MAX_DIMENSION]f64 = {}
	for index := 0; index < n * n; index += 1 {
		value := values[index + 1]
		if value < -MAX_MATRIX_MICRO || value > MAX_MATRIX_MICRO do return -1
		a_values[index] = f64(value) / 1_000_000.0
	}
	for index := 0; index < n; index += 1 {
		rhs := values[matrix_end + index]
		guess := values[matrix_end + n + index]
		if rhs < -MAX_VECTOR_MICRO || rhs > MAX_VECTOR_MICRO || guess < -MAX_VECTOR_MICRO || guess > MAX_VECTOR_MICRO do return -1
		b[index] = f64(rhs) / 1_000_000.0
		x[index] = f64(guess) / 1_000_000.0
	}
	min_micro := values[vector_end]
	max_micro := values[vector_end + 1]
	iterations := values[vector_end + 2]
	tolerance_micro := values[vector_end + 3]
	if min_micro < 1 || max_micro <= min_micro || max_micro > MAX_SPECTRAL_MICRO || iterations < 1 || iterations > MAX_ITERATIONS || tolerance_micro < 1 || tolerance_micro > MAX_VECTOR_MICRO do return -1
	min_eigenvalue := f64(min_micro) / 1_000_000.0
	max_eigenvalue := f64(max_micro) / 1_000_000.0
	tolerance := f64(tolerance_micro) / 1_000_000.0
	output_bytes := n * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	for row := 0; row < n; row += 1 {
		product := 0.0
		for column := 0; column < n; column += 1 { product += a_values[row * n + column] * x[column] }
		residual[row] = b[row] - product
	}
	d := (max_eigenvalue + min_eigenvalue) / 2.0
	c := (max_eigenvalue - min_eigenvalue) / 2.0
	alpha := 0.0
	alpha_previous := 0.0
	for iteration := i64(0); iteration < iterations; iteration += 1 {
		squares := 0.0
		for index := 0; index < n; index += 1 { squares += residual[index] * residual[index] }
		if math.sqrt_f64(squares) < tolerance do break
		if iteration == 0 {
			alpha = 1.0 / d
			for index := 0; index < n; index += 1 { direction[index] = residual[index] }
		} else {
			half_step := c * alpha_previous / 2.0
			beta := half_step * half_step
			alpha = 1.0 / (d - beta / alpha_previous)
			direction_scale := beta / alpha_previous
			for index := 0; index < n; index += 1 { direction[index] = residual[index] + direction_scale * direction[index] }
		}
		for index := 0; index < n; index += 1 { x[index] += alpha * direction[index] }
		for row := 0; row < n; row += 1 {
			product := 0.0
			for column := 0; column < n; column += 1 { product += a_values[row * n + column] * x[column] }
			residual[row] = b[row] - product
		}
		alpha_previous = alpha
	}
	for index := 0; index < n; index += 1 { write_f64_le(output, index * 8, x[index]) }
	return i64(output_bytes)
}
