package string_left_rotation

import "core:c"

MAX_STRING_LENGTH :: 256
MAX_PARSEABLE_INPUT_LENGTH :: 259

@(export)
string_left_rotation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	raw_length, raw_rotation := input[0], input[1]
	if raw_length < 0 || raw_length > MAX_STRING_LENGTH || raw_rotation < 0 || raw_rotation > raw_length do return -1
	text_length := int(raw_length)
	if int(length) != text_length + 2 do return -1
	units: [MAX_STRING_LENGTH]u16
	for i := 0; i < text_length; i += 1 {
		if input[i + 2] < 0 || input[i + 2] > 65535 do return -1
		units[i] = u16(input[i + 2])
	}
	required := text_length * 2
	if required == 0 do return 0
	if output == nil || capacity < c.size_t(required) do return -2
	rotation := int(raw_rotation)
	for i := 0; i < text_length; i += 1 {
		source := rotation + i
		if source >= text_length do source -= text_length
		value := units[source]
		output[2 * i] = u8(value & 0xff)
		output[2 * i + 1] = u8(value >> 8)
	}
	return i64(required)
}
