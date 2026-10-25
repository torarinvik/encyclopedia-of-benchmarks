package tsvc_s128_strided_coupled_update

import "core:c"

// Clean-room port of TSVC s128; see package README for provenance and rights.
MAX_N :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s128_strided_coupled_update :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(1 + 5 * MAX_N) do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	b_count := 2 * n
	if length != c.size_t(1 + 5 * n) do return -1
	var a: [MAX_N]i64
	var b, c: [2 * MAX_N]i64
	var d: [MAX_N]i64
	for i := 0; i < b_count; i += 1 {
		b[i] = input[1 + i]
		c[i] = input[1 + b_count + i]
		if b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 do return -1
	}
	for i := 0; i < n; i += 1 {
		d[i] = input[1 + 2 * b_count + i]
		if d[i] < -100 || d[i] > 100 do return -1
	}
	output_values := 3 * n
	if output == nil || capacity < c.size_t(8 * output_values) do return -2
	j := -1
	for i := 0; i < n; i += 1 {
		k := j + 1
		a[i] = b[k] - d[i]
		j = k + 1
		b[k] = a[i] + c[k]
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	for i := 0; i < b_count; i += 1 { store_i64_le(output, 8 * (n + i), b[i]) }
	return i64(output_values)
}
