package remove_duplicate_from_string

import "core:c"

MAX_TEXT_LENGTH :: 512
MAX_INPUT_LENGTH :: MAX_TEXT_LENGTH + 2

@(export)
remove_duplicate_from_string :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	text_length_value := input[0]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
	text_length := int(text_length_value)
	if int(length) != 1 + text_length do return -1

	result: [MAX_TEXT_LENGTH]u8 = {}
	seen: [128]bool = {}
	result_length := 0
	for index in 0..<text_length {
		value := input[index + 1]
		if value < 0 || value > 127 do return -1
		byte := int(value)
		if !seen[byte] {
			seen[byte] = true
			result[result_length] = u8(value)
			result_length += 1
		}
	}

	if c.size_t(result_length) > output_capacity || (result_length != 0 && output == nil) do return -2
	for index in 0..<result_length { output[index] = result[index] }
	return i64(result_length)
}
