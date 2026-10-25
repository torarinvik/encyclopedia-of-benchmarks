package tsvc_s162_guarded_shifted_fma

import "core:c"

// Clean-room bounded port of TSVC s162; see package README for provenance.
MAX_N :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s162_guarded_shifted_fma :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 194 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > 1 do return -1
	n := int(input[0])
	if length != c.size_t(2 + 3 * n) do return -1
	for i := 2; i < int(length); i += 1 {
		if input[i] < -2 || input[i] > 2 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	a_offset := 2
	b_offset := a_offset + n
	c_offset := b_offset + n
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8 * i, input[a_offset + i])
	}
	if input[1] > 0 {
		for i := 0; i < n-1; i += 1 {
			value := input[a_offset + i + 1] + input[b_offset + i] * input[c_offset + i]
			store_i64_le(output, 8 * i, value)
		}
	}
	return i64(n)
}
