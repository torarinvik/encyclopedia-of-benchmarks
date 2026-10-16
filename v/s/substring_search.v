module main

@[export: 'substring_search']
pub fn substring_search(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 195 { return -2 }
		text_length := values[0]
		pattern_length := values[1]
		if text_length < 0 || text_length > 128 || pattern_length < 0 || pattern_length > 64 { return -2 }
		if length != usize(2 + text_length + pattern_length) { return -2 }
		text_start := usize(2)
		pattern_start := text_start + usize(text_length)
		for i in text_start .. length { if values[i] < 1 || values[i] > 127 { return -2 } }
		mut text_index := usize(0)
		mut pattern_index := usize(0)
		mut match_start := i64(-1)
		for text_index < usize(text_length) {
			mut expected := i64(0)
			if pattern_index < usize(pattern_length) { expected = values[pattern_start + pattern_index] }
			if values[text_start + text_index] == expected {
				if match_start == -1 { match_start = i64(text_index) }
				pattern_index++
				if pattern_index == usize(pattern_length) { return match_start }
				text_index++
			} else {
				match_start = -1
				pattern_index = 0
				text_index++
			}
		}
		return -1
	}
}
