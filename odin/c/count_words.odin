package count_words

import "core:c"

MAX_LENGTH :: 4096

is_trim_character :: proc(value: i64) -> bool { return value <= 32 }
is_regex_whitespace :: proc(value: i64) -> bool {
	return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32
}

// Count tokens after Java String.trim() and split("\\s+").
@(export)
count_words :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length > 0 && values == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if values[i] < 0 || values[i] > 127 do return -1
	}
	if length == 0 do return 0
	start := c.size_t(0)
	ending := length
	for start < ending && is_trim_character(values[start]) do start += 1
	for ending > start && is_trim_character(values[ending - 1]) do ending -= 1
	if start == ending do return 1
	count := i64(0)
	in_word := false
	for i := start; i < ending; i += 1 {
		if is_regex_whitespace(values[i]) {
			in_word = false
		} else if !in_word {
			count += 1
			in_word = true
		}
	}
	return count
}
