package convolution_f2_64

import "core:c"

MAX_N :: 8
MAX_M :: 8
MAX_PARSEABLE :: 19

multiply_in_field :: proc(left_value, right_value: u64) -> u64 {
	shifted := left_value
	multiplier := right_value
	product := u64(0)
	for bit := 0; bit < 64; bit += 1 {
		if (multiplier & 1) != 0 do product ^= shifted
		carry := shifted >> 63
		shifted <<= 1
		if carry != 0 do shifted ^= 0x1b
		multiplier >>= 1
	}
	return product
}

@(export)
convolution_f2_64 :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2 + n + m) do return -1
	count := n + m - 1
	needed := c.size_t(8 * count)
	if output == nil || output_capacity < needed do return -2

	a := [MAX_N]u64{}
	b := [MAX_M]u64{}
	product := [MAX_N + MAX_M - 1]u64{}
	for i := 0; i < n; i += 1 do a[i] = transmute(u64)input[2 + i]
	for j := 0; j < m; j += 1 do b[j] = transmute(u64)input[2 + n + j]
	for i := 0; i < n; i += 1 {
		for j := 0; j < m; j += 1 {
			product[i + j] ^= multiply_in_field(a[i], b[j])
		}
	}
	for i := 0; i < count; i += 1 {
		bits := product[i]
		for byte := 0; byte < 8; byte += 1 {
			output[8 * i + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
	return i64(needed)
}
