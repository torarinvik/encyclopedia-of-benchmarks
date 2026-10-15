package permutation_in_string

import "core:c"

MAX_STRING_LENGTH :: 1024
MAX_INPUT_LENGTH :: 2050

adjust_count :: proc "contextless" (differences: [^]i64, nonzero: ^i64, letter: int, amount: i64) {
	if differences[letter] == 0 do nonzero^ += 1
	differences[letter] += amount
	if differences[letter] == 0 do nonzero^ -= 1
}

// Check for a permutation of one lowercase ASCII string inside another.
@(export)
permutation_in_string :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > MAX_INPUT_LENGTH do return -1
	first_length_value := input[0]
	second_length_value := input[1]
	if first_length_value < 0 || first_length_value > MAX_STRING_LENGTH || second_length_value < 0 || second_length_value > MAX_STRING_LENGTH do return -1
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 97 || input[index] > 122 do return -1
	}
	if first_length > second_length do return 0

	differences: [26]i64 = {}
	nonzero: i64 = 0
	for index := 0; index < first_length; index += 1 {
		adjust_count(&differences[0], &nonzero, int(input[2+index]-97), 1)
		adjust_count(&differences[0], &nonzero, int(input[2+first_length+index]-97), -1)
	}
	if nonzero == 0 do return 1
	for start := 0; start < second_length-first_length; start += 1 {
		outgoing := 2 + first_length + start
		incoming := outgoing + first_length
		adjust_count(&differences[0], &nonzero, int(input[outgoing]-97), 1)
		adjust_count(&differences[0], &nonzero, int(input[incoming]-97), -1)
		if nonzero == 0 do return 1
	}
	return 0
}
