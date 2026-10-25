package tsvc_s125_matrix_flattened_fma

import "core:c"

// Clean-room port of TSVC s125; see package README for provenance and rights.
MAX_N :: 8
MAX_CELLS :: MAX_N * MAX_N

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s125_matrix_flattened_fma :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(1 + 3 * MAX_CELLS) do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	cells := n * n
	if length != c.size_t(1 + 3 * cells) do return -1
	var aa, bb, cc, result: [MAX_CELLS]i64
	for i := 0; i < cells; i += 1 {
		aa[i] = input[1 + i]
		bb[i] = input[1 + cells + i]
		cc[i] = input[1 + 2 * cells + i]
		if aa[i] < -100 || aa[i] > 100 || bb[i] < -100 || bb[i] > 100 || cc[i] < -100 || cc[i] > 100 do return -1
	}
	if output == nil || capacity < c.size_t(8 * cells) do return -2
	k := 0
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			result[k] = aa[k] + bb[k] * cc[k]
			k += 1
		}
	}
	for i := 0; i < cells; i += 1 { store_i64_le(output, 8 * i, result[i]) }
	return i64(cells)
}
