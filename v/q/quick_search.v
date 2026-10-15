module quick_search

// Return the first ASCII byte match using a lookahead-byte shift table.
@[export: 'quick_search']
pub fn quick_search(values &i64, length usize) i64 {
	if length < 2 || length > 512 { return -1 }
	text_length_value := unsafe { values[0] }
	pattern_length_value := unsafe { values[1] }
	if text_length_value < 0 || text_length_value > 255 || pattern_length_value < 0 || pattern_length_value > 255 { return -1 }
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for index in 0 .. text_length + pattern_length {
		byte := unsafe { values[2 + index] }
		if byte < 0 || byte > 127 { return -1 }
	}
	if pattern_length == 0 { return 0 }
	if pattern_length > text_length { return -1 }

	mut shift := [128]int{init: pattern_length}
	pattern_start := 2 + text_length
	for index in 0 .. pattern_length {
		shift[int(unsafe { values[pattern_start + index] })] = pattern_length - index
	}

	mut position := 0
	for position <= text_length - pattern_length {
		mut index := pattern_length
		for index > 0 && unsafe { values[2 + position + index - 1] == values[pattern_start + index - 1] } {
			index--
		}
		if index == 0 { return i64(position) }
		if position + pattern_length >= text_length { break }
		position += shift[int(unsafe { values[2 + position + pattern_length] })]
	}
	return -1
}
