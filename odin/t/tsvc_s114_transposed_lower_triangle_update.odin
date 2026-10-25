package tsvc_s114_transposed_lower_triangle_update

import "core:c"

// Clean-room port of TSVC s114; see package README for provenance and rights.
MAX_N :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s114_transposed_lower_triangle_update :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > c.size_t(1 + 2 * MAX_N * MAX_N) do return -1
	if input[0] < 2 || input[0] > MAX_N do return -1
	n := int(input[0])
	cells := n * n
	if length != c.size_t(1 + 2 * cells) do return -1
	var a, b: [MAX_N * MAX_N]i64
	for i in 0 ..< cells {
		a[i] = input[1 + i]
		b[i] = input[1 + cells + i]
		if a[i] < -1_000_000 || a[i] > 1_000_000 || b[i] < -1_000_000 || b[i] > 1_000_000 do return -1
	}
	output_bytes := 8 * cells
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i in 0 ..< n {
		for j in 0 ..< i do a[i*n+j] = a[j*n+i] + b[i*n+j]
	}
	for i in 0 ..< cells do store_i64_le(output, 8*i, a[i])
	return i64(cells)
}
