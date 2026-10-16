module bitap_exact_match_31

const max_text_length = 4096
const max_pattern_length = 31

@[export: 'bitap_exact_match_31']
pub fn bitap_exact_match_31(values &i64, length usize) i64 {
	if values == nil || length < 2 { return -2 }
	unsafe {
		text_value := values[0]
		pattern_value := values[1]
		if text_value < 0 || text_value > max_text_length || pattern_value < 0 || pattern_value > max_pattern_length { return -2 }
		text_length := int(text_value)
		pattern_length := int(pattern_value)
		if length != usize(2 + text_length + pattern_length) { return -2 }
		for i in 2 .. int(length) { if values[i] < 97 || values[i] > 122 { return -2 } }
		if pattern_length == 0 { return 0 }
		if pattern_length > text_length { return -1 }
		mut masks := [26]u32{}
		for c in 0 .. 26 { masks[c] = ~u32(0) }
		for i in 0 .. pattern_length {
			letter := int(values[2 + text_length + i] - 97)
			masks[letter] &= ~(u32(1) << u32(i))
		}
		mut state := ~u32(1)
		for i in 0 .. text_length {
			letter := int(values[2 + i] - 97)
			state |= masks[letter]
			state <<= 1
			if state & (u32(1) << u32(pattern_length)) == 0 { return i64(i - pattern_length + 1) }
		}
		return -1
	}
}
