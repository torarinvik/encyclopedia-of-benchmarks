module bitap_string_match

const max_text_length = 4096
const max_pattern_length = 63

@[export: 'bitap_string_match']
pub fn bitap_string_match(values &i64, length usize) i64 {
	if length < 2 { return -2 }
	text_value := unsafe { values[0] }
	pattern_value := unsafe { values[1] }
	if text_value < 0 || text_value > max_text_length || pattern_value < 0 || pattern_value > max_pattern_length { return -2 }
	text_length := int(text_value)
	pattern_length := int(pattern_value)
	if length != usize(2 + text_length + pattern_length) { return -2 }
	for index in 2 .. int(length) {
		value := unsafe { values[index] }
		if value < 97 || value > 122 { return -2 }
	}
	if pattern_length == 0 { return 0 }
	if pattern_length > text_length { return -1 }

	mut masks := [26]u64{}
	for letter in 0 .. 26 { masks[letter] = ~u64(0) }
	for index in 0 .. pattern_length {
		letter := int(unsafe { values[2 + text_length + index] } - 97)
		masks[letter] &= ~(u64(1) << index)
	}
	mut state := ~u64(1)
	for index in 0 .. text_length {
		letter := int(unsafe { values[2 + index] } - 97)
		state |= masks[letter]
		state <<= 1
		if state & (u64(1) << pattern_length) == 0 { return i64(index - pattern_length + 1) }
	}
	return -1
}
