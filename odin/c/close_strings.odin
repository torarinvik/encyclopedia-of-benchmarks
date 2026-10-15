package close_strings

import "core:c"

// Check lowercase strings for equal letter sets and frequency multisets.
@(export)
close_strings :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 514 do return -1
	first_length_value := input[0]
	second_length_value := input[1]
	if first_length_value < 0 || first_length_value > 256 || second_length_value < 0 || second_length_value > 256 do return -1
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length do return -1
	first: [26]i64 = {}
	second: [26]i64 = {}
	for index := 0; index < first_length; index += 1 {
		value := input[index + 2]
		if value < 97 || value > 122 do return -1
		first[int(value - 97)] += 1
	}
	second_start := 2 + first_length
	for index := 0; index < second_length; index += 1 {
		value := input[second_start + index]
		if value < 97 || value > 122 do return -1
		second[int(value - 97)] += 1
	}
	if first_length != second_length do return 0
	first_frequencies: [257]i64 = {}
	second_frequencies: [257]i64 = {}
	for letter := 0; letter < 26; letter += 1 {
		if (first[letter] == 0) != (second[letter] == 0) do return 0
		first_frequencies[int(first[letter])] += 1
		second_frequencies[int(second[letter])] += 1
	}
	for frequency := 0; frequency <= 256; frequency += 1 {
		if first_frequencies[frequency] != second_frequencies[frequency] do return 0
	}
	return 1
}
