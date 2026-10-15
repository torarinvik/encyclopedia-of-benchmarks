package check_anagram

import "core:c"

MAX_STRING_LENGTH :: 1024
MAX_INPUT_LENGTH :: 2050

letter_index :: proc(value: i64) -> int {
	if value >= 97 && value <= 122 do return int(value - 97)
	if value >= 65 && value <= 90 do return int(value - 65)
	return -1
}

// Case-insensitive anagram check for distinct ASCII alphabetic strings.
@(export)
check_anagram :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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
		letter := letter_index(input[2 + index])
		if letter < 0 do return -1
		first_counts[letter] += 1
	}
	for index := 0; index < second_length; index += 1 {
		letter := letter_index(input[2 + first_length + index])
		if letter < 0 do return -1
		second_counts[letter] += 1
	}
	if first_length != second_length do return 0
	different_after_normalization := false
	for index := 0; index < first_length; index += 1 {
		if letter_index(input[2 + index]) != letter_index(input[2 + first_length + index]) {
			different_after_normalization = true
		}
	}
	if !different_after_normalization do return 0
	for letter := 0; letter < 26; letter += 1 {
		if first_counts[letter] != second_counts[letter] do return 0
	}
	return 1
}
