package tsvc_s332_first_above_threshold

import "core:c"

// Clean-room bounded port of TSVC s332; see package README for provenance.
MAX_N :: 256

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s332_first_above_threshold :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 258 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < -1000000 || input[1] > 1000000 do return -1
	n := int(input[0])
	threshold := input[1]
	if length != c.size_t(2 + n) do return -1
	var values: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		values[i] = input[2 + i]
		if values[i] < -1000000 || values[i] > 1000000 do return -1
	}
	if output == nil || capacity < 16 do return -2
	index := i64(-2)
	value := i64(-1)
	for i := 0; i < n; i += 1 {
		if values[i] > threshold {
			index = i64(i)
			value = values[i]
			break
		}
	}
	store_i64_le(output, 0, index)
	store_i64_le(output, 8, value)
	return 2
}
