package random

import "core:c"

MAX_COUNT :: 256
MAX_INPUT_LENGTH :: 5
MAX_OUTPUT_BYTES :: MAX_COUNT * 4

write_u32_le :: proc "contextless" (output: [^]u8, index: int, value: u32) {
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(value >> u32(8*byte))
	}
}

rotate_right :: proc(value, rotation: u32) -> u32 {
	left_shift := (32 - rotation) & 31
	return (value >> rotation) | (value << left_shift)
}

pcg32_random :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if length != 4 do return -1

	seed := transmute(u64)values[0]
	multiplier := transmute(u64)values[1]
	stream_value, count_value := values[2], values[3]
	if stream_value < 0 || count_value < 0 || count_value > i64(MAX_COUNT) do return -1

	stream := u64(stream_value)
	increment := (stream << 1) | 1
	state := seed +% increment
	state = state *% multiplier +% increment
	count := int(count_value)
	required_bytes := count * 4
	if required_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(required_bytes) do return -2

	for index := 0; index < count; index += 1 {
		value := state
		rotation := u32(value >> 59)
		state = state *% multiplier +% increment
		value ^= value >> 18
		xorshifted := u32(value >> 27)
		write_u32_le(output, index, rotate_right(xorshifted, rotation))
	}
	return i64(required_bytes)
}
