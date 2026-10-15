package camel_case_to_snake_case

import "core:c"

@(export)
camel_case_to_snake_case :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if length == 0 || length > 256 || input == nil do return -1

	output_length := 0
	for i := 0; i < int(length); i += 1 {
		value := input[i]
		if value >= 65 && value <= 90 {
			if i > 0 do output_length += 1
		} else if value < 97 || value > 122 {
			return -1
		}
		output_length += 1
	}
	if int(capacity) < output_length || output == nil do return -2

	position := 0
	for i := 0; i < int(length); i += 1 {
		value := input[i]
		if value >= 65 && value <= 90 {
			if i > 0 {
				output[position] = u8('_')
				position += 1
			}
			output[position] = u8(value + 32)
		} else {
			output[position] = u8(value)
		}
		position += 1
	}
	return i64(output_length)
}
