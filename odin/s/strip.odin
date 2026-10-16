package strip

import "core:c"

strip_contains :: proc(value: i64, input: [^]i64, set_start: c.size_t,
                       set_length: i64) -> bool {
	if set_length == -1 do return value == 9 || value == 10 || value == 13 || value == 32
	for index := c.size_t(0); index < c.size_t(set_length); index += 1 {
		if input[set_start + index] == value do return true
	}
	return false
}

@(export)
strip :: proc "c" (input: [^]i64, length: c.size_t,
                    output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 386 do return -1
	if input[0] < 0 || input[0] > 256 do return -1
	text_length := c.size_t(input[0])
	set_index := 1 + text_length
	if set_index >= length do return -1
	set_length := input[set_index]
	expected_length: c.size_t
	if set_length == -1 {
		expected_length = set_index + 1
	} else {
		if set_length < 0 || set_length > 128 do return -1
		expected_length = set_index + 1 + c.size_t(set_length)
	}
	if length != expected_length do return -1
	for index := c.size_t(0); index < text_length; index += 1 {
		if input[1 + index] < 0 || input[1 + index] > 127 do return -1
	}
	if set_length >= 0 {
		for index := c.size_t(0); index < c.size_t(set_length); index += 1 {
			if input[set_index + 1 + index] < 0 || input[set_index + 1 + index] > 127 do return -1
		}
	}

	start: c.size_t = 0
	ending := text_length
	for start < ending && strip_contains(input[1 + start], input, set_index + 1, set_length) {
		start += 1
	}
	for ending > start && strip_contains(input[ending], input, set_index + 1, set_length) {
		ending -= 1
	}
	output_length := ending - start
	if output_capacity < output_length || (output_length > 0 && output == nil) do return -2
	for index := c.size_t(0); index < output_length; index += 1 {
		output[index] = u8(input[1 + start + index])
	}
	return i64(output_length)
}
