package decimal_to_binary

import "core:c"

// Write the most-significant-first binary representation of a nonnegative i64.
@(export)
decimal_to_binary :: proc "c" (value: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if value < 0 do return -1
	width := c.size_t(1)
	for remaining := value; remaining > 1; remaining /= 2 {
		width += 1
	}
	if output == nil || output_capacity < width do return -2

	position := width
	remaining := value
	for position > 0 {
		position -= 1
		output[position] = u8('0') + u8(remaining % 2)
		remaining /= 2
	}
	return i64(width)
}
