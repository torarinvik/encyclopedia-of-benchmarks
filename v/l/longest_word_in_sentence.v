module longest_word_in_sentence

fn is_ascii_whitespace(value i64) bool {
	return value == 32 || (value >= 9 && value <= 13)
}

@[export: 'longest_word_in_sentence']
pub fn longest_word_in_sentence(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || isnil(values) { return -1 }
	text_value := unsafe { values[0] }
	if text_value < 0 || text_value > 1024 || length != usize(1 + text_value) { return -1 }
	text_length := int(text_value)
	for index in 0 .. text_length {
		byte := unsafe { values[index + 1] }
		if !is_ascii_whitespace(byte) && (byte < 33 || byte > 126) { return -1 }
	}

	mut best_start := 0
	mut best_length := 0
	mut index := 0
	for index < text_length {
		if is_ascii_whitespace(unsafe { values[index + 1] }) { index++; continue }
		start := index
		for index < text_length && !is_ascii_whitespace(unsafe { values[index + 1] }) { index++ }
		word_length := index - start
		if word_length > best_length { best_start = start; best_length = word_length }
	}
	if usize(best_length) > output_capacity || (best_length > 0 && isnil(output)) { return -2 }
	mut written := 0
	for byte in 0 .. best_length {
		unsafe { output[written] = u8(values[1 + best_start + byte]) }
		written++
	}
	return i64(best_length)
}
