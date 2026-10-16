package conjugate_gradient

import "core:c"

MAX_DIMENSION :: 8
MAX_ENTRY_MICRO :: 1_000_000_000
SCALE :: 1_000_000.0
TOLERANCE :: 1.0e-10
MAX_ITERATIONS :: 1000

write_f64_le :: proc "contextless"(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
conjugate_gradient :: proc "c" (values: [^]i64, length: c.size_t,
									 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return -1
	n := int(values[0])
	if length != c.size_t(1 + n * n + n) do return -1
	vector_offset := 1 + n * n
	coefficients: [MAX_DIMENSION * MAX_DIMENSION]f64 = {}
	rhs: [MAX_DIMENSION]f64 = {}
	solution: [MAX_DIMENSION]f64 = {}
	residual: [MAX_DIMENSION]f64 = {}
	direction: [MAX_DIMENSION]f64 = {}
	product: [MAX_DIMENSION]f64 = {}
	for index := 0; index < n * n + n; index += 1 {
		if values[index + 1] < -MAX_ENTRY_MICRO || values[index + 1] > MAX_ENTRY_MICRO do return -1
	}
	for row := 0; row < n; row += 1 {
		diagonal := values[1 + row * n + row]
		if diagonal <= 0 do return -1
		off_diagonal_sum: i64 = 0
		for column := 0; column < n; column += 1 {
			entry := values[1 + row * n + column]
			if entry != values[1 + column * n + row] do return -1
			if column != row {
				if entry < 0 {
					off_diagonal_sum -= entry
				} else {
					off_diagonal_sum += entry
				}
			}
			coefficients[row * n + column] = f64(entry) / SCALE
		}
		if diagonal <= off_diagonal_sum do return -1
		rhs[row] = f64(values[vector_offset + row]) / SCALE
		residual[row] = rhs[row]
		direction[row] = rhs[row]
	}
	output_bytes := n * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	residual_squared: f64 = 0
	for index := 0; index < n; index += 1 {
		residual_squared += residual[index] * residual[index]
	}
	for iteration := 0; iteration < MAX_ITERATIONS; iteration += 1 {
		if residual_squared <= TOLERANCE * TOLERANCE do break
		for row := 0; row < n; row += 1 {
			product[row] = 0
			for column := 0; column < n; column += 1 {
				product[row] += coefficients[row * n + column] * direction[column]
			}
		}
		denominator: f64 = 0
		for index := 0; index < n; index += 1 {
			denominator += direction[index] * product[index]
		}
		if denominator <= 0 do return -1
		alpha := residual_squared / denominator
		for index := 0; index < n; index += 1 {
			solution[index] += alpha * direction[index]
			residual[index] -= alpha * product[index]
		}
		next_residual_squared: f64 = 0
		for index := 0; index < n; index += 1 {
			next_residual_squared += residual[index] * residual[index]
		}
		if next_residual_squared <= TOLERANCE * TOLERANCE {
			residual_squared = next_residual_squared
			break
		}
		beta := next_residual_squared / residual_squared
		for index := 0; index < n; index += 1 {
			direction[index] = residual[index] + beta * direction[index]
		}
		residual_squared = next_residual_squared
	}
	for index := 0; index < n; index += 1 do write_f64_le(output, index * 8, solution[index])
	return i64(output_bytes)
}
