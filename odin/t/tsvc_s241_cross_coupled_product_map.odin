package tsvc_s241_cross_coupled_product_map

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 4 * MAX_N
MAX_VALUE :: i64(2)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s241_cross_coupled_product_map :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 2 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + 4 * n do return -1

	a_start := 1
	b_start := a_start + n
	c_start := b_start + n
	d_start := c_start + n
	var a, b: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[a_start + i]
		b[i] = input[b_start + i]
		if a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
			b[i] < -MAX_VALUE || b[i] > MAX_VALUE ||
			input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
			input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE do return -1
	}
	if output == nil || output_capacity < c.size_t(16 * n) do return -2

	for i := 0; i < n - 1; i += 1 {
		next_a := a[i + 1]
		a[i] = b[i] * input[c_start + i] * input[d_start + i]
		b[i] = a[i] * next_a * input[d_start + i]
	}
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8 * i, a[i])
		store_i64_le(output, 8 * (n + i), b[i])
	}
	return i64(2 * n)
}
