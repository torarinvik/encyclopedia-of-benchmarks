package boyer_moore_horspool

import "core:c"

MAX_INPUT_VALUES :: 512

count_matches :: proc(values: [^]i64, text_length, pattern_length, pattern_start: c.size_t,
		shifts: [128]c.size_t) -> c.size_t {
	if pattern_length == 0 do return text_length + 1
	if pattern_length > text_length do return 0
	count := c.size_t(0)
	start := c.size_t(0)
	for start <= text_length - pattern_length {
		current := pattern_length
		for current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1] { current -= 1 }
		if current == 0 {
			count += 1
			start += 1
		} else {
			tail := c.size_t(values[2 + start + pattern_length - 1])
			start += shifts[tail]
		}
	}
	return count
}

@(export)
boyer_moore_horspool :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	if values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255 do return -1
	text_length := c.size_t(values[0])
	pattern_length := c.size_t(values[1])
	if length != 2 + text_length + pattern_length do return -1
	pattern_start := 2 + text_length
	for index := c.size_t(0); index < text_length + pattern_length; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 127 do return -1
	}

	shifts: [128]c.size_t
	for byte := c.size_t(0); byte < 128; byte += 1 { shifts[byte] = pattern_length }
	for index := c.size_t(0); index + 1 < pattern_length; index += 1 {
		shifts[c.size_t(values[pattern_start + index])] = pattern_length - 1 - index
	}
	match_count := count_matches(values, text_length, pattern_length, pattern_start, shifts)
	if output_capacity < match_count || (match_count > 0 && output == nil) do return -2

	written := c.size_t(0)
	if pattern_length == 0 {
		for position := c.size_t(0); position <= text_length; position += 1 {
			output[written] = u8(position)
			written += 1
		}
	} else if pattern_length <= text_length {
		for start := c.size_t(0); start <= text_length - pattern_length; {
			current := pattern_length
			for current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1] { current -= 1 }
			if current == 0 {
				output[written] = u8(start)
				written += 1
				start += 1
			} else {
				tail := c.size_t(values[2 + start + pattern_length - 1])
				start += shifts[tail]
			}
		}
	}
	return i64(written)
}
