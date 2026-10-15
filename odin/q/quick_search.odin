package quick_search

import "core:c"

// Return the first ASCII byte match using a lookahead-byte shift table.
@(export)
quick_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 512 do return -1
	if values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255 do return -1
	text_length := c.size_t(values[0])
	pattern_length := c.size_t(values[1])
	if length != 2 + text_length + pattern_length do return -1
	for index := c.size_t(0); index < text_length + pattern_length; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 127 do return -1
	}
	if pattern_length == 0 do return 0
	if pattern_length > text_length do return -1

	shift: [128]c.size_t
	for byte := c.size_t(0); byte < 128; byte += 1 { shift[byte] = pattern_length }
	pattern_start := 2 + text_length
	for index := c.size_t(0); index < pattern_length; index += 1 {
		shift[int(values[pattern_start + index])] = pattern_length - index
	}

	position := c.size_t(0)
	for position <= text_length - pattern_length {
		index := pattern_length
		for index > 0 && values[2 + position + index - 1] == values[pattern_start + index - 1] {
			index -= 1
		}
		if index == 0 do return i64(position)
		if position + pattern_length >= text_length do break
		position += shift[int(values[2 + position + pattern_length])]
	}
	return -1
}
