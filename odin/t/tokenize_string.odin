package tokenize_string

import "core:c"

tokenize_string :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	if input[0] < 0 || input[0] > 128 do return -1
	text_length := c.size_t(input[0])
	if length != text_length + 2 do return -1
	separator := input[1]
	if separator != 44 && separator != 46 && separator != 58 do return -1
	separator_count := c.size_t(0)
	for index := c.size_t(0); index < text_length; index += 1 {
		byte := input[index + 2]
		if byte < 32 || byte > 126 do return -1
		if byte == separator do separator_count += 1
	}
	if separator_count > 18 do return -1
	output_length := text_length + 2
	if output == nil || capacity < output_length do return -2
	output[0] = u8(separator_count + 1)
	for index := c.size_t(0); index < text_length; index += 1 {
		byte := input[index + 2]
		if byte == separator do output[index + 1] = 0 else output[index + 1] = u8(byte)
	}
	output[output_length - 1] = 0
	return i64(output_length)
}
