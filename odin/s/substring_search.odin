package substring_search

import "core:c"

@(export)
substring_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 195 do return -2
	text_length, pattern_length := values[0], values[1]
	if text_length < 0 || text_length > 128 || pattern_length < 0 || pattern_length > 64 do return -2
	if length != c.size_t(2 + text_length + pattern_length) do return -2
	text_start := c.size_t(2)
	pattern_start := text_start + c.size_t(text_length)
	for i := text_start; i < length; i += 1 { if values[i] < 1 || values[i] > 127 do return -2 }
	text_index := c.size_t(0)
	pattern_index := c.size_t(0)
	match_start: i64 = -1
	for text_index < c.size_t(text_length) {
		expected: i64 = 0
		if pattern_index < c.size_t(pattern_length) do expected = values[pattern_start + pattern_index]
		if values[text_start + text_index] == expected {
			if match_start == -1 do match_start = i64(text_index)
			pattern_index += 1
			if pattern_index == c.size_t(pattern_length) do return match_start
			text_index += 1
		} else {
			match_start = -1
			pattern_index = 0
			text_index += 1
		}
	}
	return -1
}
