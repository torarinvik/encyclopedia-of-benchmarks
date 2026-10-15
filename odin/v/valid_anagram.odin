package valid_anagram

import "core:c"

MAX_STRING_LENGTH :: 1024
MAX_INPUT_LENGTH :: 2 + 2 * MAX_STRING_LENGTH

// Compare lowercase ASCII strings by their letter frequencies.
@(export)
valid_anagram :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	first_length_value := input[0]
	second_length_value := input[1]
	if first_length_value < 0 || first_length_value > MAX_STRING_LENGTH || second_length_value < 0 || second_length_value > MAX_STRING_LENGTH do return -1
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length do return -1
	first_counts: [26]int
	second_counts: [26]int
	for index := 0; index < first_length; index += 1 {
		value := input[2 + index]
		if value < 97 || value > 122 do return -1
		first_counts[int(value - 97)] += 1
	}
	for index := 0; index < second_length; index += 1 {
		value := input[2 + first_length + index]
		if value < 97 || value > 122 do return -1
		second_counts[int(value - 97)] += 1
	}
	for letter := 0; letter < 26; letter += 1 {
		if first_counts[letter] != second_counts[letter] do return 0
	}
	return 1
}
