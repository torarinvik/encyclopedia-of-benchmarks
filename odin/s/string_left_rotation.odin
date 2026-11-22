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
	if text_length == 0 do return 0
	units: [MAX_STRING_LENGTH]u16
	observed_bits: u64
	for i := 0; i < text_length; i += 1 {
		value := u64(input[i + 2])
		observed_bits |= value
		units[i] = u16(value)
	}
	if observed_bits > 65535 do return -1
	required := text_length * 2
	if output == nil || capacity < c.size_t(required) do return -2
	rotation := int(raw_rotation)
	for source := rotation; source < text_length; source += 1 {
		destination := 2 * (source - rotation)
		value := units[source]
		output[destination] = u8(value & 0xff)
		output[destination + 1] = u8(value >> 8)
	}
	suffix_bytes := 2 * (text_length - rotation)
	for source := 0; source < rotation; source += 1 {
		destination := suffix_bytes + 2 * source
		value := units[source]
		output[destination] = u8(value & 0xff)
		output[destination + 1] = u8(value >> 8)
	}
	return i64(required)
}
