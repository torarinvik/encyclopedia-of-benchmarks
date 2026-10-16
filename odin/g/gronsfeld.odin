package gronsfeld

import "core:c"

// Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
@(export)
gronsfeld :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 321 do return -1
	separator := c.size_t(0)
	for separator < length && input[separator] != 0 { separator += 1 }
	if separator == length do return -1
	text_length := separator
	key_length := length - separator - 1
	if text_length > 256 || key_length < 1 || key_length > 64 do return -1

	for index := c.size_t(0); index < text_length; index += 1 {
		if input[index] < 1 || input[index] > 127 do return -1
	}
	for index := c.size_t(0); index < key_length; index += 1 {
		value := input[separator + 1 + index]
		if value < 48 || value > 57 do return -1
	}
	if output_capacity < text_length || (text_length > 0 && output == nil) do return -2

	key_index := c.size_t(0)
	for index := c.size_t(0); index < text_length; index += 1 {
		value := input[index]
		mapped := value
		if value >= 65 && value <= 90 {
			shift := input[separator + 1 + key_index % key_length] - 48
			mapped = 65 + (value - 65 + shift) % 26
			key_index += 1
		} else if value >= 97 && value <= 122 {
			shift := input[separator + 1 + key_index % key_length] - 48
			mapped = 97 + (value - 97 + shift) % 26
			key_index += 1
		}
		output[index] = u8(mapped)
	}
	return i64(text_length)
}
