package autokey_cipher

import "core:c"

uppercase_letter :: proc(value: i64) -> i64 {
	if value >= 97 && value <= 122 do return value - 32
	return value
}

@(export)
autokey_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 2052 do return -1
	mode := input[0]
	dialect := input[1]
	text_length_value := input[2]
	key_length_value := input[3]
	if (mode != 0 && mode != 1) || (dialect != 0 && dialect != 1) || text_length_value < 1 || text_length_value > 1024 || key_length_value < 1 || key_length_value > 1024 do return -1
	text_length := c.size_t(text_length_value)
	key_length := c.size_t(key_length_value)
	if length != 4 + text_length + key_length do return -1
	key_start := 4 + text_length
	for index := c.size_t(0); index < text_length; index += 1 {
		value := input[4 + index]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
		if dialect == 1 && mode == 1 && value >= 65 && value <= 90 do return -1
	}
	for index := c.size_t(0); index < key_length; index += 1 {
		value := input[key_start + index]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
	}
	if output_capacity < text_length || output == nil do return -2
	for index := c.size_t(0); index < text_length; index += 1 {
		plain := uppercase_letter(input[4 + index]) - 65
		key_value := i64(0)
		if index < key_length { key_value = uppercase_letter(input[key_start + index]) }
		else if mode == 0 { key_value = uppercase_letter(input[4 + index - key_length]) }
		else { key_value = uppercase_letter(i64(output[index - key_length])) }
		shift := key_value - 65
		mapped := (plain + shift) % 26
		if mode == 1 do mapped = (plain - shift + 26) % 26
		result := 65 + mapped
		if dialect == 1 do result += 32
		output[index] = u8(result)
	}
	return i64(text_length)
}
