package longest_consecutive_characters

import "core:c"

@(export)
longest_consecutive_characters :: proc "c" (values: [^]i64, length: c.size_t,
										 output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 257 do return -1
	count_value := values[0]
	if count_value < 1 || count_value > 256 || length != c.size_t(count_value+1) do return -1
	count := int(count_value)
	for index in 0..<count {
		if values[index+1] < 0 || values[index+1] > 127 do return -1
	}
	if output == nil || capacity < 3 do return -2

	best_character := values[1]
	best_length, current_length := 1, 1
	for index in 1..<count {
		if values[index+1] == values[index] {
			current_length += 1
			if current_length > best_length {
				best_length = current_length
				best_character = values[index+1]
			}
		} else {
			current_length = 1
		}
	}
	output[0] = u8(best_character)
	output[1] = u8(best_length & 255)
	output[2] = u8(best_length >> 8)
	return 3
}
