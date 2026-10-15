package rotate_array_reversal

import "core:c"

MAX_ARRAY_LENGTH :: 1024
MAX_INPUT_LENGTH :: 1025

reverse_range :: proc "contextless" (values: [^]i32, start_value, end_value: int) {
	start := start_value
	ending := end_value
	for start < ending {
		ending -= 1
		if start >= ending do break
		temporary := values[start]
		values[start] = values[ending]
		values[ending] = temporary
		start += 1
	}
}

// Rotate by reversing the whole array, then each side of the rotation.
@(export)
rotate_array_reversal :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || length > MAX_INPUT_LENGTH do return -1
	steps := input[0]
	if steps < -2147483648 || steps > 2147483647 do return -1
	count := int(length) - 1
	values: [MAX_ARRAY_LENGTH]i32 = {}
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	output_bytes := c.size_t(count * 4)
	if output_capacity < output_bytes do return -2
	shift := 0
	if count != 0 {
		shift = int(steps % i64(count))
		if shift < 0 do shift += count
	}
	reverse_range(&values[0], 0, count)
	reverse_range(&values[0], 0, shift)
	reverse_range(&values[0], shift, count)
	for index := 0; index < count; index += 1 {
		bits := u32(values[index])
		for byte := 0; byte < 4; byte += 1 {
			output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
		}
	}
	return i64(count)
}
