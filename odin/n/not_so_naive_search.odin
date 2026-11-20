package not_so_naive_search

import "core:c"

MAX_TEXT :: 512
MIN_PATTERN :: 2
MAX_PATTERN :: 64
MAX_INPUT :: 578

@(export)
not_so_naive_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT do return -2
	raw_text, raw_pattern := values[0], values[1]
	if raw_text < 0 || raw_text > MAX_TEXT || raw_pattern < MIN_PATTERN || raw_pattern > MAX_PATTERN do return -2
	text_length, pattern_length := int(raw_text), int(raw_pattern)
	if length != c.size_t(2 + text_length + pattern_length) do return -2
	pattern_start := 2 + text_length
	for i := 0; i < text_length + pattern_length; i += 1 {
		byte := values[2+i]
		if byte < 0 || byte > 127 do return -2
	}
	if pattern_length > text_length do return -1

	same_prefix := values[pattern_start] == values[pattern_start+1]
	mismatch_shift := 1
	post_check_shift := 2
	if same_prefix { mismatch_shift, post_check_shift = 2, 1 }
	position := 0
	last_start := text_length - pattern_length
	for position <= last_start {
		if values[pattern_start+1] != values[2+position+1] {
			position += mismatch_shift
			continue
		}
		pattern_index := 2
		for pattern_index < pattern_length && values[pattern_start+pattern_index] == values[2+position+pattern_index] {
			pattern_index += 1
		}
		if pattern_index == pattern_length && values[pattern_start] == values[2+position] do return i64(position)
		position += post_check_shift
	}
	return -1
}
