package hilbert_curve_index_encode

import "core:c"

MAX_ORDER :: 8

hilbert_index :: proc "contextless" (order, x, y: i64) -> i64 {
	current_x, current_y, distance := x, y, i64(0)
	for bit_index := order - 1; bit_index >= 0; bit_index -= 1 {
		bit := i64(1) << bit_index
		x_bit := i64((current_x & bit) != 0)
		y_bit := i64((current_y & bit) != 0)
		distance += bit * bit * ((3 * x_bit) ^ y_bit)
		mask := bit - 1
		low_x, low_y := current_x & mask, current_y & mask
		if y_bit == 0 {
			if x_bit != 0 {
				low_x = mask - low_x
				low_y = mask - low_y
			}
			current_x, current_y = low_y, low_x
		} else {
			current_x, current_y = low_x, low_y
		}
	}
	return distance
}

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
hilbert_curve_index_encode :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	order := input[0]
	if order < 1 || order > MAX_ORDER do return -1
	side := i64(1) << order
	x, y := input[1], input[2]
	if x < 0 || x >= side || y < 0 || y >= side do return -1
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, hilbert_index(order, x, y))
	return 8
}
