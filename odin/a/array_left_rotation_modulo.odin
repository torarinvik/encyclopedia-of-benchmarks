package array_left_rotation_modulo

import "core:c"

MAX_ARRAY_LENGTH :: 1024
MAX_INPUT_LENGTH :: 1025

write_i32_le :: proc(output: [^]u8, index: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

// Return a fresh left rotation; nonpositive shifts keep order and positive shifts wrap.
@(export)
array_left_rotation_modulo :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	rotations := input[0]
	if rotations < -2147483648 || rotations > 2147483647 do return -1
	count := int(length) - 1
	values: [MAX_ARRAY_LENGTH]i32 = {}
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	if count == 0 do return 0
	shift := 0
	if rotations > 0 do shift = int(rotations % i64(count))
	output_bytes := c.size_t(count * 4)
	if output_capacity < output_bytes || output == nil do return -2
	for index := shift; index < count; index += 1 {
		write_i32_le(output, index - shift, values[index])
	}
	for index := 0; index < shift; index += 1 {
		write_i32_le(output, count - shift + index, values[index])
	}
	return i64(count)
}

