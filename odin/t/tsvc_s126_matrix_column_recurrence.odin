package tsvc_s126_matrix_column_recurrence

import "core:c"

// Clean-room port of TSVC s126; see package README for provenance and rights.
MAX_N :: 6
MAX_CELLS :: MAX_N * MAX_N

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s126_matrix_column_recurrence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 13 || length > c.size_t(1 + 3 * MAX_CELLS) do return -1
	if input[0] < 2 || input[0] > MAX_N do return -1
	n := int(input[0])
	cells := n * n
	if length != c.size_t(1 + 3 * cells) do return -1
	var coefficients, c_matrix, b_matrix: [MAX_CELLS]i64
	for i := 0; i < cells; i += 1 {
		coefficients[i] = input[1 + i]
		c_matrix[i] = input[1 + cells + i]
		b_matrix[i] = input[1 + 2 * cells + i]
		if coefficients[i] < -100 || coefficients[i] > 100 ||
			c_matrix[i] < -100 || c_matrix[i] > 100 || b_matrix[i] < -100 || b_matrix[i] > 100 do return -1
	}
	if output == nil || capacity < c.size_t(8 * cells) do return -2
	k := 1
	for i := 0; i < n; i += 1 {
		for j := 1; j < n; j += 1 {
			target := j * n + i
			b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target]
			k += 1
		}
		k += 1
	}
	for i := 0; i < cells; i += 1 { store_i64_le(output, 8 * i, b_matrix[i]) }
	return i64(cells)
}
