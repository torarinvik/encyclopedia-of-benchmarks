package tsvc_s124_conditional_fma_map

import "core:c"

// Clean-room port of TSVC s124; see package README for provenance and rights.
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s124_conditional_fma_map :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(1 + 4 * MAX_N) do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	var a, b, c, d, e: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		b[i] = input[1 + i]
		c[i] = input[1 + n + i]
		d[i] = input[1 + 2 * n + i]
		e[i] = input[1 + 3 * n + i]
		if b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
			d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	j := -1
	for i := 0; i < n; i += 1 {
		if b[i] > 0 {
			j += 1
			a[j] = b[i] + d[i] * e[i]
		} else {
			j += 1
			a[j] = c[i] + d[i] * e[i]
		}
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
