package snake_case_to_camel_pascal_case

import "core:c"

@(export)
snake_case_to_camel_pascal_case :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 257 do return -1
	if input[0] != 0 && input[0] != 1 do return -1

	input_length := int(length) - 1
	output_length := 0
	for i := 0; i < input_length; i += 1 {
		value := input[i + 1]
		if value == 95 {
			if i == 0 || i + 1 == input_length || input[i] == 95 do return -1
		} else if !((value >= 97 && value <= 122) || (value >= 48 && value <= 57)) {
			return -1
		} else {
			output_length += 1
		}
	}
	if int(capacity) < output_length || output == nil do return -2

	capitalize := input[0] == 1
	position := 0
	for i := 0; i < input_length; i += 1 {
		value := input[i + 1]
		if value == 95 {
			capitalize = true
			continue
		}
		if capitalize && value >= 97 && value <= 122 do value -= 32
		output[position] = u8(value)
		position += 1
		capitalize = false
	}
	return i64(output_length)
}
