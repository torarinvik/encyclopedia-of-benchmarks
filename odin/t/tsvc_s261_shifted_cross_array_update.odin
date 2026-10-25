package tsvc_s261_shifted_cross_array_update

import "core:c"

// Clean-room bounded port of TSVC s261; see package README for provenance.
MAX_N :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s261_shifted_cross_array_update :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > 257 do return -1
	if input[0] < 2 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	var a, b, c, d: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[1 + i]
		b[i] = input[1 + n + i]
		c[i] = input[1 + 2 * n + i]
		d[i] = input[1 + 3 * n + i]
		if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
			c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 do return -1
	}
	if output == nil || capacity < c.size_t(16 * n) do return -2
	for i := 1; i < n; i += 1 {
		temporary := a[i] + b[i]
		a[i] = temporary + c[i - 1]
		product := c[i] * d[i]
		c[i] = product
	}
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8 * i, a[i])
		store_i64_le(output, 8 * (n + i), c[i])
	}
	return i64(2 * n)
}
