package longest_word_in_sentence

import "core:c"

is_ascii_whitespace :: proc "contextless" (value: i64) -> bool {
	return value == 32 || (value >= 9 && value <= 13)
}

@(export)
longest_word_in_sentence :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > 1024 ||
		length != c.size_t(1 + values[0]) { return -1 }
	text_length := int(values[0])
	for index := 0; index < text_length; index += 1 {
		byte := values[index + 1]
		if !is_ascii_whitespace(byte) && (byte < 33 || byte > 126) { return -1 }
	}

	best_start := 0
	best_length := 0
	index := 0
	for index < text_length {
		if is_ascii_whitespace(values[index + 1]) { index += 1; continue }
		start := index
		for index < text_length && !is_ascii_whitespace(values[index + 1]) { index += 1 }
		word_length := index - start
		if word_length > best_length { best_start = start; best_length = word_length }
	}
	if c.size_t(best_length) > output_capacity || (best_length > 0 && output == nil) { return -2 }
	for byte := 0; byte < best_length; byte += 1 {
		output[byte] = u8(values[1 + best_start + byte])
	}
	return i64(best_length)
}
