package vernam_cipher

import "core:c"

@(export)
vernam_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 2051 do return -1
	mode := input[0]
	text_length_value := input[1]
	key_length_value := input[2]
	if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 1024 || key_length_value < 1 || key_length_value > 1024 do return -1
	text_length := c.size_t(text_length_value)
	key_length := c.size_t(key_length_value)
	if length != 3 + text_length + key_length do return -1
	key_start := 3 + text_length
	for index := c.size_t(0); index < text_length; index += 1 {
		if input[3 + index] < 65 || input[3 + index] > 90 do return -1
	}
	for index := c.size_t(0); index < key_length; index += 1 {
		if input[key_start + index] < 65 || input[key_start + index] > 90 do return -1
	}
	if output_capacity < text_length do return -2
	for index := c.size_t(0); index < text_length; index += 1 {
		text_value := input[3 + index] - 65
		key_value := input[key_start + index % key_length] - 65
		mapped := (text_value + key_value) % 26
		if mode == 1 do mapped = (text_value - key_value + 26) % 26
		output[index] = u8(65 + mapped)
	}
	return i64(text_length)
}
