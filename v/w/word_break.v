module word_break

// Bottom-up word segmentation over packed lowercase ASCII letter codes.
@[export: 'word_break']
pub fn word_break(values &i64, length usize) i64 {
	if length < 2 || length > 1122 { return -1 }
	text_length_value := unsafe { values[0] }
	word_count_value := unsafe { values[1] }
	if text_length_value < 0 || text_length_value > 64 || word_count_value < 0 || word_count_value > 32 { return -1 }
	text_length := int(text_length_value)
	word_count := int(word_count_value)
	dictionary_start := 2 + text_length
	if length != usize(dictionary_start + word_count * 33) { return -1 }
	for index in 0 .. text_length {
		code := unsafe { values[2 + index] }
		if code < 1 || code > 26 { return -1 }
	}
	for word in 0 .. word_count {
		slot := dictionary_start + word * 33
		word_length_value := unsafe { values[slot] }
		if word_length_value < 1 || word_length_value > 32 { return -1 }
		word_length := int(word_length_value)
		for index in 0 .. 32 {
			code := unsafe { values[slot + 1 + index] }
			if index < word_length {
				if code < 1 || code > 26 { return -1 }
			} else if code != 0 {
				return -1
			}
		}
	}

	mut reachable := [65]bool{}
	reachable[0] = true
	for start in 0 .. text_length {
		if !reachable[start] { continue }
		for word in 0 .. word_count {
			slot := dictionary_start + word * 33
			word_length := int(unsafe { values[slot] })
			if word_length > text_length - start { continue }
			mut index := 0
			for index < word_length && unsafe { values[2 + start + index] } == unsafe { values[slot + 1 + index] } {
				index++
			}
			if index == word_length { reachable[start + word_length] = true }
		}
	}
	return i64(reachable[text_length])
}
