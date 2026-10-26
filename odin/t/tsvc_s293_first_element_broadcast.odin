// Clean-room implementation of TSVC s293; see package rights note.
package tsvc_s293_first_element_broadcast

import "core:c"

MAX_N :: 32
MAX_INPUT_LENGTH :: 33

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 {
		output[offset + b] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s293_first_element_broadcast :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_N || length != c.size_t(1 + input[0]) do return -1
	n := int(input[0])
	for i := 1; i < n + 1; i += 1 {
		if input[i] < -8 || input[i] > 8 do return -1
	}
	bytes := 8*n
	if output == nil || capacity < c.size_t(bytes) do return -2
	var staged: [MAX_N]i64
	for i := 0; i < n; i += 1 { staged[i] = input[1] }
	for i := 0; i < n; i += 1 { store_i64_le(output, 8*i, staged[i]) }
	return i64(bytes)
}
