package chudnovsky_algorithm

import "core:c"

MAX_PRECISION :: 12

sqrt_10005 :: proc "contextless" () -> f64 {
	root := 100.0
	for iteration := 0; iteration < 8; iteration += 1 { root = 0.5 * (root + 10005.0 / root) }
	return root
}

@(export)
chudnovsky_algorithm :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_PRECISION do return -1
	precision := int(values[0])
	output_length := precision
	if precision == 1 do output_length = 0
	if capacity < c.size_t(output_length) || (output_length > 0 && output == nil) do return -2
	if precision == 1 do return 0

	pi := (426880.0 * sqrt_10005()) / 13591409.0
	fraction := pi - 3.0
	output[0] = u8('3')
	output[1] = u8('.')
	for digit := 0; digit < precision - 2; digit += 1 {
		fraction *= 10.0
		next_digit := int(fraction)
		output[2 + digit] = u8('0' + next_digit)
		fraction -= f64(next_digit)
	}
	return i64(output_length)
}
