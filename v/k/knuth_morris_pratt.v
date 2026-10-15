module knuth_morris_pratt

// Return the first byte match index, or -1 when there is no match.
@[export: 'knuth_morris_pratt']
pub fn knuth_morris_pratt(input_values &i64, length usize) i64 {
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

	pattern_start := 2 + text_length
	mut prefix := [4096]usize{init: 0}
	mut index := 1
	mut matched := 0
	for index < pattern_length {
		for matched > 0 && unsafe { input_values[pattern_start + index] } != unsafe { input_values[pattern_start + matched] } {
			matched = int(prefix[matched - 1])
		}
		if unsafe { input_values[pattern_start + index] } == unsafe { input_values[pattern_start + matched] } { matched++ }
		prefix[index] = usize(matched)
		index++
	}

	index = 0
	matched = 0
	for index < text_length {
		for matched > 0 && unsafe { input_values[2 + index] } != unsafe { input_values[pattern_start + matched] } {
			matched = int(prefix[matched - 1])
		}
		if unsafe { input_values[2 + index] } == unsafe { input_values[pattern_start + matched] } { matched++ }
		if matched == pattern_length { return i64(index + 1 - pattern_length) }
		index++
	}
	return -1
}
