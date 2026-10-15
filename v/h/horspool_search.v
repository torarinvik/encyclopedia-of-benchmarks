module horspool_search

@[export: 'horspool_search']
pub fn horspool_search(packed &i64, length usize) i64 {
	if length < 2 { return -2 }
	text_length_value := unsafe { packed[0] }
	pattern_length_value := unsafe { packed[1] }
	if text_length_value < 0 || text_length_value > 512 || pattern_length_value < 0 || pattern_length_value > 64 { return -2 }
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != usize(text_length + pattern_length + 2) { return -2 }
	pattern_start := 2 + text_length
	for index in 0 .. text_length {
		ch := unsafe { packed[index + 2] }
		if ch < 0 || ch > 127 { return -2 }
	}
	for index in 0 .. pattern_length {
		ch := unsafe { packed[pattern_start + index] }
		if ch < 0 || ch > 127 { return -2 }
	}
	if pattern_length == 0 || pattern_length > text_length { return -1 }
	mut shifts := [128]int{init: pattern_length}
	for index := pattern_length - 2; index >= 0; index-- {
		ch := int(unsafe { packed[pattern_start + index] })
		if shifts[ch] == pattern_length { shifts[ch] = pattern_length - 1 - index }
	}
	mut end_index := pattern_length - 1
	for end_index < text_length {
		mut offset := 0
		for offset < pattern_length && unsafe { packed[pattern_start + pattern_length - 1 - offset] == packed[2 + end_index - offset] } { offset++ }
		if offset == pattern_length { return i64(end_index - pattern_length + 1) }
		end_index += shifts[int(unsafe { packed[2 + end_index] })]
	}
	return -1
}
