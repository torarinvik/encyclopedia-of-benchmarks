package max_word

import "core:c"

MAX_TEXT_LENGTH :: 512
MAX_INPUT_LENGTH :: MAX_TEXT_LENGTH + 2

lower_ascii :: proc(value: u8) -> u8 {
	if value >= 'A' && value <= 'Z' do return value + ('a' - 'A')
	return value
}

@(export)
max_word :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	text_length_value := input[0]
	if text_length_value < 1 || text_length_value > MAX_TEXT_LENGTH do return -1
	text_length := int(text_length_value)
	if int(length) != 1 + text_length do return -1

	text: [MAX_TEXT_LENGTH]u8 = {}
	for i in 0..<text_length {
		value := input[i + 1]
		is_letter := (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
		if value == 32 {
			if i == 0 || i + 1 == text_length || text[i - 1] == ' ' do return -1
		} else if !is_letter || value == 73 {
			return -1
		}
		text[i] = u8(value)
	}

	starts: [MAX_TEXT_LENGTH]int = {}
	lengths: [MAX_TEXT_LENGTH]int = {}
	counts: [MAX_TEXT_LENGTH]int = {}
	unique_count := 0
	start := 0
	for start < text_length {
		end := start
		for end < text_length && text[end] != ' ' { end += 1 }
		word_length := end - start
		if word_length > 6 do return -1
		mut found := unique_count
		for key in 0..<unique_count {
			if lengths[key] != word_length { continue }
			offset := 0
			for offset < word_length && lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset]) {
				offset += 1
			}
			if offset == word_length { found = key; break }
		}
		if found == unique_count {
			starts[unique_count] = start
			lengths[unique_count] = word_length
			counts[unique_count] = 1
			unique_count += 1
		} else {
			counts[found] += 1
		}
		start = end + 1
	}

	mut winner := 0
	for key in 1..<unique_count { if counts[key] > counts[winner] { winner = key } }
	result_length := lengths[winner]
	if output_capacity < c.size_t(result_length) || output == nil do return -2
	single_word := unique_count == 1 && counts[0] == 1
	for i in 0..<result_length {
		value := text[starts[winner] + i]
		output[i] = if single_word then value else lower_ascii(value)
	}
	return i64(result_length)
}
