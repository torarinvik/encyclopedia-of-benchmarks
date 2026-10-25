package tsvc_s132_shifted_row_update

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 2 + 3 * MAX_N
MAX_VALUE :: i64(1_000_000)

bounded_value :: proc "contextless" (value: i64) -> bool {
	return value >= -MAX_VALUE && value <= MAX_VALUE
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s132_shifted_row_update :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 8 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 2 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 2 + 3 * n do return -1

	row_start := 1
	target_start := row_start + n
	b_start := target_start + n
	c1_index := b_start + n
	var target: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		target[i] = input[target_start + i]
		if !bounded_value(input[row_start + i]) || !bounded_value(target[i]) ||
			!bounded_value(input[b_start + i]) do return -1
	}
	c1 := input[c1_index]
	if !bounded_value(c1) do return -1
	if output == nil || output_capacity < c.size_t(8 * n) do return -2

	for i := 1; i < n; i += 1 {
		target[i] = input[row_start + i - 1] + input[b_start + i] * c1
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, target[i]) }
	return i64(n)
}
