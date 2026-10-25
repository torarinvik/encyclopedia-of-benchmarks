package tsvc_s161_mutually_exclusive_updates

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 5 * MAX_N
MAX_VALUE :: i64(2)

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
tsvc_s161_mutually_exclusive_updates :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 11 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 2 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + 5 * n do return -1

	a_start := 1
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	e_start := d_start + n
	var a, c: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[a_start + i]
		c[i] = input[c_start + i]
		if !bounded_value(a[i]) || !bounded_value(input[b_start + i]) ||
			!bounded_value(c[i]) || !bounded_value(input[d_start + i]) ||
			!bounded_value(input[e_start + i]) do return -1
	}
	if output == nil || output_capacity < c.size_t(16 * n) do return -2

	for i := 0; i + 1 < n; i += 1 {
		if input[b_start + i] < 0 {
			d := input[d_start + i]
			c[i + 1] = a[i] + d * d
		} else {
			a[i] = c[i] + input[d_start + i] * input[e_start + i]
		}
	}
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8 * i, a[i])
		store_i64_le(output, 8 * (n + i), c[i])
	}
	return i64(2 * n)
}
