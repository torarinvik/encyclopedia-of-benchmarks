package naive_search

import "core:c"

MAX_INPUT_VALUES :: 512

@(export)
naive_search :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	if values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255 do return -1
	text_length := c.size_t(values[0])
	pattern_length := c.size_t(values[1])
	if length != 2 + text_length + pattern_length do return -1
	pattern_start := 2 + text_length
	for index := c.size_t(0); index < text_length; index += 1 {
		if values[2 + index] < 1 || values[2 + index] > 127 do return -1
	}
	for index := c.size_t(0); index < pattern_length; index += 1 {
		if values[pattern_start + index] < 1 || values[pattern_start + index] > 127 do return -1
	}

	match_count := c.size_t(0)
	if pattern_length <= text_length {
		for start := c.size_t(0); start <= text_length - pattern_length; start += 1 {
			offset := c.size_t(0)
			for offset < pattern_length && values[2 + start + offset] == values[pattern_start + offset] {
				offset += 1
			}
			if offset == pattern_length do match_count += 1
		}
	}
	if output_capacity < match_count || (match_count > 0 && output == nil) do return -2
	written := c.size_t(0)
	if pattern_length <= text_length {
		for start := c.size_t(0); start <= text_length - pattern_length; start += 1 {
			offset := c.size_t(0)
			for offset < pattern_length && values[2 + start + offset] == values[pattern_start + offset] {
				offset += 1
			}
			if offset == pattern_length {
				output[written] = u8(start)
				written += 1
			}
		}
	}
	return i64(written)
}
