package tsvc_s1221_lag4_add_recurrence

import "core:c"

// Clean-room port of TSVC s1221; see package README for provenance and rights.
MIN_N :: 5
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s1221_lag4_add_recurrence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 11 || length > 65 do return -1
	if input[0] < MIN_N || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 2 * n) do return -1
	var a, b: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[1 + i]
		b[i] = input[1 + n + i]
		if a[i] < -10 || a[i] > 10 || b[i] < -10 || b[i] > 10 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	for i := 4; i < n; i += 1 { b[i] = b[i - 4] + a[i] }
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, b[i]) }
	return i64(n)
}
