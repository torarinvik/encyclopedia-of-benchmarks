package binary_to_gray

import "core:c"

// Convert an ASCII binary string to equal-width ASCII Gray code.
@(export)
binary_to_gray :: proc "c" (bits: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
	if bits == nil || length < 1 || length > 66 do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if bits[index] != 48 && bits[index] != 49 do return -1
	}
	if output == nil || output_capacity < length do return -2
	for index: c.size_t = 0; index < length; index += 1 {
		current := bits[index] - 48
		previous := i64(0)
		if index > 0 do previous = bits[index - 1] - 48
		output[index] = u8(48 + (current ^ previous))
	}
	return i64(length)
}
