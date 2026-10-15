package reverse_words

import "core:c"

@(export)
reverse_words :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 0 || input[0] > 256 do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	if output == nil || output_capacity < c.size_t(n + 1) do return -2
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if !(value == 32 || (value >= 33 && value <= 126)) do return -1
		if value == 32 && (index == 0 || index + 1 == n || input[index] == 32) do return -1
	}
	written := 0
	ending := n
	for ending > 0 {
		start := ending
		for start > 0 && input[start] != 32 { start -= 1 }
		word_start := start
		for index := word_start; index < ending; index += 1 {
			output[written] = u8(input[index + 1])
			written += 1
		}
		if word_start == 0 { break }
		output[written] = 32
		written += 1
		ending = start - 1
	}
	output[written] = 0
	return i64(written)
}
