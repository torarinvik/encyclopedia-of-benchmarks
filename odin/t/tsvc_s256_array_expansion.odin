package tsvc_s256_array_expansion

import "core:c"

// Clean-room bounded port of TSVC s256; see package README for provenance.
MAX_N :: 16
MAX_CELLS :: MAX_N * MAX_N
MAX_INPUT_LENGTH :: 2 + MAX_N + 2 * MAX_CELLS
MAX_C0 :: i64(1_000_000)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> u64(byte*8)) & 255)
	}
}

@(export)
tsvc_s256_array_expansion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw, a0 := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || a0 < -1000 || a0 > 1000 do return -1
	n := int(n_raw)
	cells := n * n
	if length != c.size_t(2 + n + 2 * cells) do return -1
	d_start, b_start, c_start := 2, 2+n, 2+n+cells
	for i := 0; i < n; i += 1 {
		if input[d_start+i] < -1000 || input[d_start+i] > 1000 do return -1
	}
	for i := 0; i < cells; i += 1 {
		if input[b_start+i] < -1000 || input[b_start+i] > 1000 ||
			input[c_start+i] < -MAX_C0 || input[c_start+i] > MAX_C0 do return -1
	}
	output_values := n + cells
	if output == nil || output_capacity < c.size_t(output_values*8) do return -2

	var a: [MAX_N]i64
	var c_values: [MAX_CELLS]i64
	a[0] = a0
	for cell := 0; cell < cells; cell += 1 { c_values[cell] = input[c_start+cell] }
	for column := 0; column < n; column += 1 {
		for row := 1; row < n; row += 1 {
			a[row] = 1 - a[row-1]
			cell := row*n + column
			c_values[cell] = a[row] + input[b_start+cell] * input[d_start+row]
		}
	}
	for row := 0; row < n; row += 1 { store_i64_le(output, row*8, a[row]) }
	for cell := 0; cell < cells; cell += 1 { store_i64_le(output, (n+cell)*8, c_values[cell]) }
	return i64(output_values)
}
