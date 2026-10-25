package tsvc_s4117_pair_replicated_gather_map

import "core:c"

// Clean-room bounded port of TSVC s4117; see package README for provenance.
MAX_N :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s4117_pair_replicated_gather_map :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 161 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	c_length := (n + 1) / 2
	if length != c.size_t(1 + 2 * n + c_length) do return -1
	for i := 1; i < int(length); i += 1 {
		if input[i] < -2 || input[i] > 2 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	b_offset := 1
	c_offset := 1 + n
	d_offset := c_offset + c_length
	for i := 0; i < n; i += 1 {
		value := input[b_offset + i] + input[c_offset + i/2] * input[d_offset + i]
		store_i64_le(output, 8 * i, value)
	}
	return i64(n)
}
