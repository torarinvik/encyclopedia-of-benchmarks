package decimal_to_hexadecimal

import "core:c"

// Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
@(export)
decimal_to_hexadecimal :: proc "c" (value: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if value < 0 do return -1
	width := c.size_t(1)
	for remaining := value; remaining >= 16; remaining /= 16 { width += 1 }
	if output == nil || output_capacity < width do return -2
	position := width
	remaining := value
	for position > 0 {
		position -= 1
		digit := remaining % 16
		if digit < 10 { output[position] = u8('0') + u8(digit) }
		else { output[position] = u8('a') + u8(digit - 10) }
		remaining /= 16
	}
	return i64(width)
}
