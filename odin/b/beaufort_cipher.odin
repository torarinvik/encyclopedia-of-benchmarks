package beaufort_cipher

import "core:c"

@(export)
beaufort_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 2051 do return -1
	mode := input[0]
	text_length_value := input[1]
	key_length_value := input[2]
	if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 1024 ||
		key_length_value < 0 || key_length_value > 1024 do return -1
	text_length := c.size_t(text_length_value)
	key_length := c.size_t(key_length_value)
	if length != 3 + text_length + key_length ||
		(text_length == 0 && key_length != 0) ||
		(text_length != 0 && (key_length == 0 || key_length > text_length)) do return -1
	key_start := 3 + text_length
	for index := c.size_t(0); index < text_length; index += 1 {
		value := input[3 + index]
		if value != 32 && (value < 65 || value > 90) do return -1
	}
	for index := c.size_t(0); index < key_length; index += 1 {
		if input[key_start + index] < 65 || input[key_start + index] > 90 do return -1
	}
	if output_capacity < text_length || (text_length != 0 && output == nil) do return -2
	key_index := c.size_t(0)
	for index := c.size_t(0); index < text_length; index += 1 {
		value := input[3 + index]
		if value == 32 {
			output[index] = 32
			continue
		}
		letter := value - 65
		key_letter := input[key_start + key_index % key_length] - 65
		mapped := (letter + key_letter) % 26
		if mode == 0 do mapped = (letter - key_letter + 26) % 26
		output[index] = u8(65 + mapped)
		key_index += 1
	}
	return i64(text_length)
}
