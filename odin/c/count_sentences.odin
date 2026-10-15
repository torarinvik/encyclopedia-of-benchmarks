package count_sentences

import "core:c"

MAX_TEXT_LENGTH :: 4096

is_trim_byte :: proc "contextless" (value: u8) -> bool {
	return value == 0 || value == 9 || value == 10 || value == 11 || value == 13 || value == 32
}
is_regex_space :: proc "contextless" (value: u8) -> bool {
	return (value >= 9 && value <= 13) || value == 32
}
is_word_byte :: proc "contextless" (value: u8) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
		(value >= 48 && value <= 57) || value == 95
}
is_terminator :: proc "contextless" (value: u8) -> bool {
	return value == 46 || value == 33 || value == 63
}
is_eligible_predecessor :: proc "contextless" (value: u8) -> bool {
	return !is_regex_space(value) && value != 124 && value != 94 && value != 46
}

@(export)
count_sentences :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_TEXT_LENGTH + 1) do return -1
	if input[0] < 0 || input[0] > i64(MAX_TEXT_LENGTH) || length != c.size_t(input[0] + 1) do return -1
	text_length := int(input[0])
	text: [MAX_TEXT_LENGTH]u8
	for index := 0; index < text_length; index += 1 {
		if input[index + 1] < 0 || input[index + 1] > 127 do return -1
		text[index] = u8(input[index + 1])
	}

	begin_index := 0
	end_index := text_length
	for begin_index < end_index && is_trim_byte(text[begin_index]) do begin_index += 1
	for end_index > begin_index && is_trim_byte(text[end_index - 1]) do end_index -= 1
	cursor := begin_index
	count := i64(0)
	for cursor + 1 < end_index {
		found := false
		for index := cursor; index + 1 < end_index; index += 1 {
			if is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
				(index + 2 == end_index || !is_word_byte(text[index + 2])) {
				count += 1
				cursor = index + 2
				found = true
				break
			}
		}
		if !found do break
	}
	return count
}
