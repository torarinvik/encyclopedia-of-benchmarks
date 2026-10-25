package tsvc_s4114_reverse_index_gather_fma

import "core:c"

// Clean-room bounded port of TSVC s4114; see package README for provenance.
MAX_N :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s4114_reverse_index_gather_fma :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 257 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	ip_offset := 1
	b_offset := 1 + n
	c_offset := 1 + 2 * n
	d_offset := 1 + 3 * n
	for i := 0; i < n; i += 1 {
		if input[ip_offset + i] < 0 || input[ip_offset + i] >= i64(n) do return -1
		if input[b_offset + i] < -2 || input[b_offset + i] > 2 ||
			input[c_offset + i] < -2 || input[c_offset + i] > 2 ||
			input[d_offset + i] < -2 || input[d_offset + i] > 2 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	for i := 0; i < n; i += 1 {
		gathered := n - 1 - int(input[ip_offset + i])
		value := input[b_offset + i] + input[c_offset + gathered] * input[d_offset + i]
		store_i64_le(output, 8 * i, value)
	}
	return i64(n)
}
