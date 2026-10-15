module boyer_moore_search

// Return the first ASCII byte match using the bad-character rule.
@[export: 'boyer_moore_search']
pub fn boyer_moore_search(input_values &i64, length usize) i64 {
	if length < 2 || length > 8194 { return -1 }
	text_length_value := unsafe { input_values[0] }
	pattern_length_value := unsafe { input_values[1] }
	if text_length_value < 0 || text_length_value > 4096 || pattern_length_value < 0 || pattern_length_value > 4096 { return -1 }
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for index in 0 .. text_length + pattern_length {
		value := unsafe { input_values[2 + index] }
		if value < 0 || value > 127 { return -1 }
	}
	if pattern_length == 0 { return 0 }
	if pattern_length > text_length { return -1 }

	pattern_start := 2 + text_length
	mut last_occurrence := [128]int{init: -1}
	for index in 0 .. pattern_length {
		last_occurrence[int(unsafe { input_values[pattern_start + index] })] = index
	}
	mut alignment := 0
	for alignment <= text_length - pattern_length {
		mut pattern_index := pattern_length
		for pattern_index > 0 && unsafe { input_values[pattern_start + pattern_index - 1] } == unsafe { input_values[2 + alignment + pattern_index - 1] } {
			pattern_index--
		}
		if pattern_index == 0 { return i64(alignment) }
		text_byte := int(unsafe { input_values[2 + alignment + pattern_index - 1] })
		mut shift := pattern_index - 1 - last_occurrence[text_byte]
		if shift < 1 { shift = 1 }
		alignment += shift
	}
	return -1
}
