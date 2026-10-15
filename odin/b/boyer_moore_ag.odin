package boyer_moore_ag

import "core:c"

MAX_INPUT_VALUES :: 512

collect_matches :: proc(values: [^]i64, text_length, pattern_length, pattern_start: c.size_t,
		positions: [^]u8) -> c.size_t {
	bad_shift: [128]c.size_t
	present: [128]bool
	suffix_skip: [256]c.size_t
	for byte := c.size_t(0); byte < 128; byte += 1 { bad_shift[byte] = 0; present[byte] = false }
	for shift := c.size_t(0); shift < 256; shift += 1 { suffix_skip[shift] = 0 }
	for index := c.size_t(0); index + 1 < pattern_length; index += 1 {
		byte := c.size_t(values[pattern_start + index])
		bad_shift[byte] = pattern_length - index - 1
		present[byte] = true
	}
	for byte := c.size_t(0); byte < 128; byte += 1 {
		if !present[byte] do continue
		shift := bad_shift[byte]
		matched := c.size_t(0)
		for matched < pattern_length - shift && values[pattern_start + pattern_length - 1 - matched] == values[pattern_start + pattern_length - 1 - shift - matched] { matched += 1 }
		suffix_skip[shift] = matched
	}

	count := c.size_t(0)
	start := c.size_t(0)
	jump := pattern_length
	for start <= text_length - pattern_length {
		skip := suffix_skip[jump]
		index := int(pattern_length) - 1
		for index >= 0 {
			if values[2 + start + c.size_t(index)] != values[pattern_start + c.size_t(index)] {
				mismatch := c.size_t(values[2 + start + c.size_t(index)])
				if present[mismatch] do jump = bad_shift[mismatch] else do jump = pattern_length
				start += jump
				break
			}
			if c.size_t(index) == pattern_length - jump do index -= int(skip)
			if index == 0 {
				positions[count] = u8(start)
				count += 1
				jump = 1
				start += 1
				break
			}
			index -= 1
		}
	}
	return count
}

@(export)
boyer_moore_ag :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	if values[0] < 0 || values[0] > 255 || values[1] < 1 || values[1] > 255 do return -1
	text_length := c.size_t(values[0])
	pattern_length := c.size_t(values[1])
	if length != 2 + text_length + pattern_length do return -1
	for index := c.size_t(0); index < text_length + pattern_length; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 127 do return -1
	}
	positions: [255]u8
	count := c.size_t(0)
	if pattern_length <= text_length do count = collect_matches(values, text_length, pattern_length, 2 + text_length, &positions[0])
	if output_capacity < count || (count > 0 && output == nil) do return -2
	for index := c.size_t(0); index < count; index += 1 { output[index] = positions[index] }
	return i64(count)
}
