package decimal_to_gray

import "core:c"

// Write the minimal-width ASCII binary form of n ^ (n >> 1).
@(export)
decimal_to_gray :: proc "c" (value: i64, output: [^]u8,
        output_capacity: c.size_t) -> i64 {
	if value < 0 do return -1
	gray := value ^ (value >> 1)
	width := c.size_t(1)
	for remaining := gray; remaining > 1; remaining /= 2 {
		width += 1
	}
	if output == nil || output_capacity < width do return -2

	position := width
	remaining := gray
	for position > 0 {
		position -= 1
		output[position] = u8('0') + u8(remaining % 2)
		remaining /= 2
	}
	return i64(width)
}
