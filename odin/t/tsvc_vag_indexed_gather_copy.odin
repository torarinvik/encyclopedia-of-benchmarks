package tsvc_vag_indexed_gather_copy

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 2 * MAX_N
MAX_VALUE :: i64(1_000_000)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_vag_indexed_gather_copy :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + 2 * n do return -1
	for i := 0; i < n; i += 1 {
		index := input[1 + i]
		value := input[1 + n + i]
		if index < 0 || index >= n_raw do return -1
		if value < -MAX_VALUE || value > MAX_VALUE do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * n) do return -2

	for i := 0; i < n; i += 1 {
		index := int(input[1 + i])
		store_i64_le(output, 8 * i, input[1 + n + index])
	}
	return i64(n)
}
