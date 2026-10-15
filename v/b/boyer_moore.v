module boyer_moore

// Return the first ASCII byte match using bad-character and good-suffix shifts.
@[export: 'boyer_moore']
pub fn boyer_moore(input_values &i64, length usize) i64 {
	if length < 2 || length > 8194 { return -1 }
	text_length_value := unsafe { input_values[0] }
	pattern_length_value := unsafe { input_values[1] }
	if text_length_value < 0 || text_length_value > 4096 || pattern_length_value < 0 || pattern_length_value > 4096 { return -1 }
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for index in 0 .. text_length + pattern_length {
		value := unsafe { input_values[2 + index] }
		if value < 0 || value > 126 { return -1 }
	}
	if pattern_length == 0 { return 0 }
	if pattern_length > text_length { return -1 }

	pattern_start := 2 + text_length
	mut last_occurrence := []int{len: 127, init: -1}
	for index in 0 .. pattern_length {
		last_occurrence[int(unsafe { input_values[pattern_start + index] })] = index
	}
	mut good_suffix := []int{len: 4097, init: 0}
	mut border_position := []int{len: 4097, init: 0}
	mut i := pattern_length
	mut j := pattern_length + 1
	border_position[i] = j
	for i > 0 {
		for j <= pattern_length && unsafe { input_values[pattern_start + i - 1] } != unsafe { input_values[pattern_start + j - 1] } {
			if good_suffix[j] == 0 { good_suffix[j] = j - i }
			j = border_position[j]
		}
		i--
		j--
		border_position[i] = j
	}
	j = border_position[0]
	i = 0
	for i <= pattern_length {
		if good_suffix[i] == 0 { good_suffix[i] = j }
		if i == j { j = border_position[j] }
		i++
	}

	mut alignment := 0
	for alignment <= text_length - pattern_length {
		mut pattern_index := pattern_length
		for pattern_index > 0 && unsafe { input_values[pattern_start + pattern_index - 1] } == unsafe { input_values[2 + alignment + pattern_index - 1] } {
			pattern_index--
		}
		if pattern_index == 0 { return i64(alignment) }
		text_byte := int(unsafe { input_values[2 + alignment + pattern_index - 1] })
		mut bad_shift := pattern_index - 1 - last_occurrence[text_byte]
		if bad_shift < 1 { bad_shift = 1 }
		alignment += max(good_suffix[pattern_index], bad_shift)
	}
	return -1
}
