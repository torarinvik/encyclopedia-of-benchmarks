package tsvc_s171_stride_indexed_accumulate

import "core:c"

// Clean-room bounded port of TSVC s171; see package README for provenance.
MAX_N :: 32
MAX_STRIDE :: 4

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s171_stride_indexed_accumulate :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 159 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_STRIDE do return -1
	n := int(input[0])
	stride := int(input[1])
	a_length := 1 + (n - 1) * stride
	if length != c.size_t(2 + a_length + n) do return -1
	for i := 0; i < a_length + n; i += 1 {
		if input[2 + i] < -8 || input[2 + i] > 8 do return -1
	}
	if output == nil || capacity < c.size_t(8 * a_length) do return -2
	for i := 0; i < a_length; i += 1 {
		store_i64_le(output, 8 * i, input[2 + i])
	}
	b_offset := 2 + a_length
	for i := 0; i < n; i += 1 {
		destination := i * stride
		store_i64_le(output, 8 * destination, input[2 + destination] + input[b_offset + i])
	}
	return i64(a_length)
}
