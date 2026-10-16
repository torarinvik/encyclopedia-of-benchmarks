package shortest_palindrome

import "core:c"

@(export)
shortest_palindrome :: proc "c" (input: [^]i64, length: c.size_t,
                                  output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 64 do return -1
	if length > 0 && input == nil do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < 32 || input[index] > 126 do return -1
	}
	if length == 0 do return 0

	suffix: [64]int = {}
	for index := 1; index < int(length); index += 1 {
		matched := suffix[index - 1]
		for matched > 0 && input[matched] != input[index] do matched = suffix[matched - 1]
		if input[matched] == input[index] do matched += 1
		suffix[index] = matched
	}

	prefix_match := 0
	for index := 0; index < int(length); index += 1 {
		reversed_value := input[int(length) - 1 - index]
		for prefix_match > 0 && reversed_value != input[prefix_match] {
			prefix_match = suffix[prefix_match - 1]
		}
		if reversed_value == input[prefix_match] do prefix_match += 1
	}

	output_length := 2 * int(length) - prefix_match
	if output == nil || output_capacity < c.size_t(output_length) do return -2
	for index := 0; index < int(length); index += 1 {
		output[index] = u8(input[int(length) - 1 - index])
	}
	for index := prefix_match; index < int(length); index += 1 {
		output[int(length) + index - prefix_match] = u8(input[index])
	}
	return i64(output_length)
}
