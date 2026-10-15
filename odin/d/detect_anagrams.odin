package detect_anagrams

import "core:c"

MAX_TEXT_LENGTH :: 16
MAX_CANDIDATE_COUNT :: 16
MAX_INPUT_LENGTH :: 290

is_ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

lowercase_ascii :: proc "contextless" (value: i64) -> i64 {
	if value >= 65 && value <= 90 do return value + 32
	return value
}

letter_index :: proc "contextless" (value: i64) -> int {
	if value >= 65 && value <= 90 do return int(value - 65)
	return int(value - 97)
}

@(export)
detect_anagrams :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_TEXT_LENGTH do return -1
	subject_length := int(input[0])
	subject_start := 1
	position := subject_start + subject_length
	if position >= int(length) do return -1
	candidate_count_value := input[position]
	position += 1
	if candidate_count_value < 0 || candidate_count_value > MAX_CANDIDATE_COUNT do return -1
	candidate_count := int(candidate_count_value)

	var subject_counts: [26]int
	for offset := 0; offset < subject_length; offset += 1 {
		value := input[subject_start+offset]
		if !is_ascii_letter(value) do return -1
		subject_counts[letter_index(value)] += 1
	}

	var match_starts: [MAX_CANDIDATE_COUNT]int
	var match_lengths: [MAX_CANDIDATE_COUNT]int
	match_count := 0
	required := 1
	for candidate := 0; candidate < candidate_count; candidate += 1 {
		if position >= int(length) do return -1
		candidate_length_value := input[position]
		position += 1
		if candidate_length_value < 0 || candidate_length_value > MAX_TEXT_LENGTH do return -1
		candidate_length := int(candidate_length_value)
		if candidate_length > int(length)-position do return -1
		candidate_start := position

		var candidate_counts: [26]int
		identical := candidate_length == subject_length
		for offset := 0; offset < candidate_length; offset += 1 {
			value := input[candidate_start+offset]
			if !is_ascii_letter(value) do return -1
			candidate_counts[letter_index(value)] += 1
			if identical && lowercase_ascii(value) != lowercase_ascii(input[subject_start+offset]) {
				identical = false
			}
		}

		same_signature := true
		for letter := 0; letter < 26; letter += 1 {
			if candidate_counts[letter] != subject_counts[letter] do same_signature = false
		}
		if same_signature && !identical {
			match_starts[match_count] = candidate_start
			match_lengths[match_count] = candidate_length
			match_count += 1
			required += candidate_length + 1
		}
		position += candidate_length
	}
	if position != int(length) do return -1
	if output == nil || capacity < c.size_t(required) do return -2

	written := 0
	for candidate := 0; candidate < match_count; candidate += 1 {
		for offset := 0; offset < match_lengths[candidate]; offset += 1 {
			output[written] = u8(input[match_starts[candidate]+offset])
			written += 1
		}
		output[written] = '\n'
		written += 1
	}
	output[written] = 0
	return i64(match_count)
}
