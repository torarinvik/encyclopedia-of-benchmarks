package word_break

import "core:c"

// Bottom-up word segmentation over packed lowercase ASCII letter codes.
@(export)
word_break :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 1122 do return -1
	text_length_value := values[0]
	word_count_value := values[1]
	if text_length_value < 0 || text_length_value > 64 || word_count_value < 0 || word_count_value > 32 do return -1
	text_length := int(text_length_value)
	word_count := int(word_count_value)
	dictionary_start := 2 + text_length
	if int(length) != dictionary_start + word_count * 33 do return -1
	for index := 0; index < text_length; index += 1 {
		if values[2 + index] < 1 || values[2 + index] > 26 do return -1
	}
	for word := 0; word < word_count; word += 1 {
		slot := dictionary_start + word * 33
		word_length_value := values[slot]
		if word_length_value < 1 || word_length_value > 32 do return -1
		word_length := int(word_length_value)
		for index := 0; index < 32; index += 1 {
			code := values[slot + 1 + index]
			if index < word_length {
				if code < 1 || code > 26 do return -1
			} else if code != 0 {
				return -1
			}
		}
	}

	reachable: [65]bool = {}
	reachable[0] = true
	for start := 0; start < text_length; start += 1 {
		if !reachable[start] do continue
		for word := 0; word < word_count; word += 1 {
			slot := dictionary_start + word * 33
			word_length := int(values[slot])
			if word_length > text_length - start do continue
			index := 0
			for index < word_length && values[2 + start + index] == values[slot + 1 + index] {
				index += 1
			}
			if index == word_length do reachable[start + word_length] = true
		}
	}
	return i64(reachable[text_length])
}
