package one_time_pad_cipher

import "core:c"

MAX_TEXT_LENGTH :: 1024

@(export)
one_time_pad_cipher :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH do return -1
	mode, count_value := input[0], input[1]
	if (mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := c.size_t(count_value)
	if length != 2 + 2 * count do return -1
	if output_capacity < count do return -2
	for index := c.size_t(0); index < count; index += 1 {
		data, key := input[2 + index], input[2 + count + index]
		if data < 0 || data > 255 || key < 0 || key > 255 do return -1
		output[index] = u8(data ^ key)
	}
	return i64(count)
}
