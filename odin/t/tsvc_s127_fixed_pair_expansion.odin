package tsvc_s127_fixed_pair_expansion

import "core:c"

// Clean-room port of TSVC s127; see package README for provenance and rights.
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s127_fixed_pair_expansion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(1 + 4 * MAX_N) do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	var b, c, d, e: [MAX_N]i64
	var a: [2 * MAX_N]i64
	for i := 0; i < n; i += 1 {
		b[i] = input[1 + i]
		c[i] = input[1 + n + i]
		d[i] = input[1 + 2 * n + i]
		e[i] = input[1 + 3 * n + i]
		if b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
			d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100 do return -1
	}
	output_values := 2 * n
	if output == nil || capacity < c.size_t(8 * output_values) do return -2
	j := -1
	for i := 0; i < n; i += 1 {
		j += 1
		a[j] = b[i] + c[i] * d[i]
		j += 1
		a[j] = b[i] + d[i] * e[i]
	}
	for i := 0; i < output_values; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(output_values)
}
