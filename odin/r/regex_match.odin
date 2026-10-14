package regex_match

import "core:c"

// Direct recursive full-string matching for the . and * regular-expression subset.
regex_match_recursive :: proc "contextless" (values: [^]i64, text_length, pattern_start, pattern_length, text_index, pattern_index: c.size_t) -> bool {
	if pattern_index == pattern_length do return text_index == text_length
	atom := values[pattern_start + pattern_index]
	if pattern_index + 1 < pattern_length && values[pattern_start + pattern_index + 1] == i64('*') {
		if regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index, pattern_index + 2) do return true
		return text_index < text_length && (atom == i64('.') || atom == values[2 + text_index]) &&
			regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index + 1, pattern_index)
	}
	return text_index < text_length && (atom == i64('.') || atom == values[2 + text_index]) &&
		regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index + 1, pattern_index + 1)
}

@(export)
regex_match :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -1
	if values[0] < 0 || values[0] > 12 || values[1] < 0 || values[1] > 20 do return -1
	text_length := c.size_t(values[0])
	pattern_length := c.size_t(values[1])
	if length != 2 + text_length + pattern_length do return -1
	pattern_start := 2 + text_length
	for index: c.size_t = 0; index < text_length; index += 1 {
		if values[2 + index] < i64('a') || values[2 + index] > i64('z') do return -1
	}
	for index: c.size_t = 0; index < pattern_length; index += 1 {
		symbol := values[pattern_start + index]
		if !((symbol >= i64('a') && symbol <= i64('z')) || symbol == i64('.') || symbol == i64('*')) do return -1
		if symbol == i64('*') && (index == 0 || values[pattern_start + index - 1] == i64('*')) do return -1
	}
	if regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0) do return 1
	return 0
}
