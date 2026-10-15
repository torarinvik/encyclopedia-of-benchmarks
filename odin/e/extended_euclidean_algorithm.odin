package extended_euclidean_algorithm

import "core:c"

// Iterative extended Euclid for positive signed-32-bit inputs.
store_i32 :: proc "contextless" (value: i64, output: [^]u8, position: c.size_t) -> c.size_t {
	magnitude := u64(value)
	if value < 0 do magnitude = u64(-value)
	bits := magnitude
	if value < 0 do bits = u64(4294967296) - magnitude
	for byte := c.size_t(0); byte < 4; byte += 1 {
		output[position + byte] = u8(bits % 256)
		bits /= 256
	}
	return position + 4
}

@(export)
extended_euclidean_algorithm :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 2 || input[0] < 1 || input[0] > 2147483647 ||
		input[1] < 1 || input[1] > 2147483647 { return -1 }
	if output_capacity < 12 do return -2

	old_r := input[0]
	remainder := input[1]
	old_x := i64(1)
	x := i64(0)
	old_y := i64(0)
	y := i64(1)
	for remainder != 0 {
		quotient := old_r / remainder
		next_r := old_r - quotient * remainder
		old_r = remainder
		remainder = next_r
		next_x := old_x - quotient * x
		old_x = x
		x = next_x
		next_y := old_y - quotient * y
		old_y = y
		y = next_y
	}
	if old_r > 2147483647 || old_x < -2147483648 || old_x > 2147483647 ||
		old_y < -2147483648 || old_y > 2147483647 { return -1 }
	written := c.size_t(0)
	written = store_i32(old_r, output, written)
	written = store_i32(old_x, output, written)
	written = store_i32(old_y, output, written)
	if written == 12 do return 3
	return -1
}
