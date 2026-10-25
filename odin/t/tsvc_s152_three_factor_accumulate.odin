package tsvc_s152_three_factor_accumulate

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 2 + 4 * MAX_N
MAX_VALUE :: i64(2)
MAX_PASSES :: 32

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
tsvc_s152_three_factor_accumulate :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw, passes_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || passes_raw < 1 || passes_raw > MAX_PASSES do return -1
	n := int(n_raw)
	if int(length) != 2 + 4 * n do return -1

	a_start := 2
	c_start := a_start + n
	d_start := c_start + n
	e_start := d_start + n
	var a: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[a_start + i]
		if !bounded_value(a[i]) || !bounded_value(input[c_start + i]) ||
			!bounded_value(input[d_start + i]) || !bounded_value(input[e_start + i]) do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * n) do return -2

	for pass := 0; pass < int(passes_raw); pass += 1 {
		for i := 0; i < n; i += 1 {
			temporary := input[d_start + i] * input[e_start + i]
			a[i] += temporary * input[c_start + i]
		}
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
