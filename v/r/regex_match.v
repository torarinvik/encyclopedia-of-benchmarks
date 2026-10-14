module regex_match

// Direct recursive full-string matching for the . and * regular-expression subset.
fn regex_match_recursive(values &i64, text_length usize, pattern_start usize, pattern_length usize,
	text_index usize, pattern_index usize) bool {
	if pattern_index == pattern_length { return text_index == text_length }
	atom := unsafe { values[pattern_start + pattern_index] }
	if pattern_index + 1 < pattern_length && unsafe { values[pattern_start + pattern_index + 1] } == 42 {
		if regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index, pattern_index + 2) {
			return true
		}
		return text_index < text_length && (atom == 46 || unsafe { values[2 + text_index] } == atom) &&
			regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index + 1, pattern_index)
	}
	return text_index < text_length && (atom == 46 || unsafe { values[2 + text_index] } == atom) &&
		regex_match_recursive(values, text_length, pattern_start, pattern_length, text_index + 1, pattern_index + 1)
}

@[export: 'regex_match']
pub fn regex_match(values &i64, length usize) i64 {
	if length < 2 { return -1 }
	if unsafe { values[0] < 0 || values[0] > 12 || values[1] < 0 || values[1] > 20 } { return -1 }
	text_length := usize(unsafe { values[0] })
	pattern_length := usize(unsafe { values[1] })
	if length != 2 + text_length + pattern_length { return -1 }
	pattern_start := 2 + text_length
	for index in 0 .. text_length {
		symbol := unsafe { values[2 + index] }
		if symbol < 97 || symbol > 122 { return -1 }
	}
	for index in 0 .. pattern_length {
		symbol := unsafe { values[pattern_start + index] }
		if !((symbol >= 97 && symbol <= 122) || symbol == 46 || symbol == 42) { return -1 }
		if symbol == 42 && (index == 0 || unsafe { values[pattern_start + index - 1] } == 42) { return -1 }
	}
	if regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0) { return 1 }
	return 0
}
