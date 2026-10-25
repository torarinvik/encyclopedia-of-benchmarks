package tsvc_s453_recurrence_weighted_scale

import "core:c"

// Clean-room port of TSVC s453; see package README for provenance and rights.
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s453_recurrence_weighted_scale :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 33 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + n) do return -1
	var b, a: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		b[i] = input[1 + i]
		if b[i] < -100 || b[i] > 100 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	s: i64 = 0
	for i := 0; i < n; i += 1 {
		s += 2
		a[i] = s * b[i]
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
