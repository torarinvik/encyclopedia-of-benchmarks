package to_lower_case

import "core:c"

MAX_LENGTH :: 4096

// Lowercase ASCII bytes without locale-dependent character handling.
@(export)
to_lower_case :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < 1 || input[index] > 127 do return -1
	}
	if output_capacity < length do return -2
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if value >= 65 && value <= 90 do value += 32
		output[index] = u8(value)
	}
	return i64(length)
}
