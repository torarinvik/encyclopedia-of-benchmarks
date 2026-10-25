package tsvc_s319_coupled_reductions

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 3 * MAX_N
MAX_VALUE :: i64(2)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s319_coupled_reductions :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + 3 * n do return -1

	c_start := 1
	d_start := c_start + n
	e_start := d_start + n
	for i := 0; i < n; i += 1 {
		if input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
			input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE ||
			input[e_start + i] < -MAX_VALUE || input[e_start + i] > MAX_VALUE do return -1
	}
	value_count := 2 * n + 1
	if output == nil || output_capacity < c.size_t(8 * value_count) do return -2

	total := i64(0)
	for i := 0; i < n; i += 1 {
		a_value := input[c_start + i] + input[d_start + i]
		b_value := input[c_start + i] + input[e_start + i]
		store_i64_le(output, 8 * i, a_value)
		store_i64_le(output, 8 * (n + i), b_value)
		total += a_value
		total += b_value
	}
	store_i64_le(output, 8 * (2 * n), total)
	return i64(value_count)
}
