package tsvc_s2101_diagonal_matrix_fma

import "core:c"

MAX_N :: 8
MAX_CELLS :: MAX_N * MAX_N
MAX_INPUT_LENGTH :: 1 + 3 * MAX_CELLS
MAX_VALUE :: i64(100)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s2101_diagonal_matrix_fma :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	cells := n * n
	if int(length) != 1 + 3 * cells do return -1
	for i := 0; i < 3 * cells; i += 1 {
		if input[i + 1] < -MAX_VALUE || input[i + 1] > MAX_VALUE do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * cells) do return -2

	for cell := 0; cell < cells; cell += 1 {
		store_i64_le(output, 8 * cell, input[cell + 1])
	}
	for i := 0; i < n; i += 1 {
		diagonal := i * n + i
		value := input[1 + diagonal] + input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal]
		store_i64_le(output, 8 * diagonal, value)
	}
	return i64(cells)
}
