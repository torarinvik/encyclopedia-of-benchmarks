package misc_lowercase

import "core:c"

MAX_CHARACTERS :: 31
MAX_OUTPUT_BYTES :: 63

@(export, link_name="misc_lowercase")
misc_lowercase :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > c.size_t(MAX_CHARACTERS + 2) do return -1
	raw_length := input[0]
	if raw_length < 0 || raw_length > MAX_CHARACTERS || input_length != c.size_t(raw_length + 1) do return -1
	length := int(raw_length)
	lowered: [MAX_CHARACTERS]u16
	ascii_flag := u8(1)
	for index := 0; index < length; index += 1 {
		raw := input[index + 1]
		if raw < 0 || raw > 65535 do return -1
		value := u16(raw)
		if value > 0x7f do ascii_flag = 0
		if value >= u16('A') && value <= u16('Z') do value += 32
		lowered[index] = value
	}
	required := 1 + 2 * length
	if output == nil || output_capacity < c.size_t(required) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	staged[0] = ascii_flag
	for index := 0; index < length; index += 1 {
		staged[1 + 2 * index] = u8(lowered[index] & 0xff)
		staged[2 + 2 * index] = u8(lowered[index] >> 8)
	}
	for index := 0; index < required; index += 1 do output[index] = staged[index]
	return i64(required)
}
