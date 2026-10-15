package binary_coded_decimal

import "core:c"

// Write the prefixed four-bit-per-decimal-digit BCD representation.
@(export)
binary_coded_decimal :: proc "c" (value: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if value < -2_147_483_648 || value > 2_147_483_647 do return -1
	normalized := value
	if normalized < 0 do normalized = 0

	digits: [10]u8
	digit_count := 0
	remaining := normalized
	for remaining > 0 {
		digits[digit_count] = u8(remaining % 10)
		digit_count += 1
		remaining /= 10
	}
	if digit_count == 0 {
		digits[0] = 0
		digit_count = 1
	}

	output_length := c.size_t(2 + digit_count * 4)
	if output == nil || output_capacity < output_length do return -2
	output[0] = u8('0')
	output[1] = u8('b')
	position := c.size_t(2)
	for digit_count > 0 {
		digit_count -= 1
		digit := digits[digit_count]
		for bit := 3; bit >= 0; bit -= 1 {
			output[position] = u8('0') + ((digit >> u8(bit)) & 1)
			position += 1
		}
	}
	return i64(output_length)
}
