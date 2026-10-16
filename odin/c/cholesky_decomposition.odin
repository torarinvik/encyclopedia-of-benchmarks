package cholesky_decomposition

import "core:c"
import "core:math"

MAX_DIMENSION :: 6
MAX_ENTRY_MICRO :: 1_000_000_000

write_f64_le :: proc "contextless"(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
cholesky_decomposition :: proc "c" (values: [^]i64, length: c.size_t,
										 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION do return -1
	n := int(values[0])
	if length != c.size_t(1 + n * n) do return -1

	matrix: [MAX_DIMENSION * MAX_DIMENSION]f64 = {}
	lower: [MAX_DIMENSION * MAX_DIMENSION]f64 = {}
	for index := 0; index < n * n; index += 1 {
		scaled := values[index + 1]
		if scaled < -MAX_ENTRY_MICRO || scaled > MAX_ENTRY_MICRO do return -1
		matrix[index] = f64(scaled) / 1_000_000.0
	}
	for row := 0; row < n; row += 1 {
		for column := 0; column < n; column += 1 {
			left := matrix[row * n + column]
			right := matrix[column * n + row]
			if math.abs(left - right) > 1.0e-8 + 1.0e-5 * math.abs(right) do return -1
		}
	}

	for row := 0; row < n; row += 1 {
		for column := 0; column <= row; column += 1 {
			sum := 0.0
			for index := 0; index < column; index += 1 {
				sum += lower[row * n + index] * lower[column * n + index]
			}
			residual := matrix[row * n + column] - sum
			if row == column {
				if residual <= 0.0 do return -1
				lower[row * n + column] = math.sqrt_f64(residual)
			} else {
				lower[row * n + column] = residual / lower[column * n + column]
			}
		}
	}

	output_bytes := n * n * 8
	if c.size_t(output_bytes) > output_capacity || output == nil do return -2
	for index := 0; index < n * n; index += 1 do write_f64_le(output, index * 8, lower[index])
	return i64(output_bytes)
}
