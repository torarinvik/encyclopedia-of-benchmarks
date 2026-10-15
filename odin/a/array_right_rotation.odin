package array_right_rotation

import "core:c"

MAX_ARRAY_LENGTH :: 1024
MAX_INPUT_LENGTH :: 1025
MAX_SHIFT :: 1024

write_i32_le :: proc "contextless" (output: [^]u8, index: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

// Return a fresh right rotation; a shift at least as large as the input size yields empty output.
@(export)
array_right_rotation :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || length > MAX_INPUT_LENGTH do return -1
	shift_value := input[0]
	if shift_value < 0 || shift_value > MAX_SHIFT do return -1
	count := int(length) - 1
	values: [MAX_ARRAY_LENGTH]i32 = {}
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	shift := int(shift_value)
	if shift >= count do return 0
	output_bytes := c.size_t(count * 4)
	if output_capacity < output_bytes do return -2
	for index := 0; index < shift; index += 1 {
		write_i32_le(output, index, values[count - shift + index])
	}
	for index := shift; index < count; index += 1 {
		write_i32_le(output, index, values[index - shift])
	}
	return i64(count)
}
