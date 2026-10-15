package rotate_array

import "core:c"

MAX_ARRAY_LENGTH :: 1024
MAX_INPUT_LENGTH :: 1025
MAX_ROTATIONS :: 1024

// Rotate an array right by repeating a one-place shift.
@(export)
rotate_array :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || length > MAX_INPUT_LENGTH do return -1
	rotations := input[0]
	if rotations < 0 || rotations > MAX_ROTATIONS do return -1
	count := int(length) - 1
	values: [MAX_ARRAY_LENGTH]i32 = {}
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	output_bytes := c.size_t(count * 4)
	if output_capacity < output_bytes do return -2
	for _ in 0 ..< int(rotations) {
		if count > 1 {
			last := values[count - 1]
			for index := count - 1; index > 0; index -= 1 { values[index] = values[index - 1] }
			values[0] = last
		}
	}
	for index := 0; index < count; index += 1 {
		bits := u32(values[index])
		for byte := 0; byte < 4; byte += 1 {
			output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
		}
	}
	return i64(count)
}
