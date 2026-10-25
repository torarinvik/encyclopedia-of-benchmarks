package tsvc_s274_dependent_conditional_overwrite

import "core:c"

// Clean-room bounded port of TSVC s274; see package README for provenance.
MAX_N :: 64
MAX_PASSES :: 8
MAX_INPUT_LENGTH :: 2 + 4 * MAX_N

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> u64(byte*8)) & 255)
	}
}

@(export)
tsvc_s274_dependent_conditional_overwrite :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw, passes_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || passes_raw < 1 || passes_raw > MAX_PASSES do return -1
	n, passes := int(n_raw), int(passes_raw)
	if length != c.size_t(2 + 4*n) do return -1
	for i := 2; i < int(length); i += 1 { if input[i] < -2 || input[i] > 2 do return -1 }
	if output == nil || output_capacity < c.size_t(16*n) do return -2

	b_start, c_start, d_start, e_start := 2, 2+n, 2+2*n, 2+3*n
	var a, b: [MAX_N]i64
	for i := 0; i < n; i += 1 { b[i] = input[b_start+i] }
	for _ in 0..<passes {
		for i := 0; i < n; i += 1 {
			a[i] = input[c_start+i] + input[e_start+i]*input[d_start+i]
			if a[i] > 0 { b[i] = a[i] + b[i] }
			else { a[i] = input[d_start+i]*input[e_start+i] }
		}
	}
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8*i, a[i])
		store_i64_le(output, 8*(n+i), b[i])
	}
	return i64(2*n)
}
