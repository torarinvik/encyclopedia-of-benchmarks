package porta_cipher

import "core:c"

@(export)
porta_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 1091 do return -1
	mode := input[0]
	text_value := input[1]
	key_value := input[2]
	if (mode != 0 && mode != 1) || text_value < 0 || text_value > 1024 || key_value < 0 || key_value > 64 do return -1
	text_length := c.size_t(text_value)
	key_length := c.size_t(key_value)
	if length != 3 + text_length + key_length || (text_length != 0 && key_length == 0) do return -1
	key_start := 3 + text_length
	for index := c.size_t(3); index < length; index += 1 {
		value := input[index]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
	}
	if output_capacity < text_length || (text_length != 0 && output == nil) do return -2
	for index := c.size_t(0); index < text_length; index += 1 {
		letter := input[3 + index]
		key_letter := input[key_start + index % key_length]
		if letter >= 97 do letter -= 32
		if key_letter >= 97 do key_letter -= 32
		letter_index := letter - 65
		group := (key_letter - 65) / 2
		mapped := (letter_index - 13 + group) % 13
		if letter_index < 13 do mapped = 13 + (letter_index + 13 - group) % 13
		output[index] = u8(65 + mapped)
	}
	return i64(text_length)
}
