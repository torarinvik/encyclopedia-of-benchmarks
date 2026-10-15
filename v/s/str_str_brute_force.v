module str_str_brute_force

// Return the first pattern occurrence using a direct character-by-character scan.
@[export: 'str_str_brute_force']
pub fn str_str_brute_force(packed &i64, length usize) i64 {
	if length < 2 || length > 2050 { return -1 }
	text_length_value := unsafe { packed[0] }
	pattern_length_value := unsafe { packed[1] }
	if text_length_value < 0 || text_length_value > 1024 ||
		pattern_length_value < 0 || pattern_length_value > 1024 { return -1 }
	text_length := int(text_length_value)
	pattern_length := int(pattern_length_value)
	if length != usize(2 + text_length + pattern_length) { return -1 }
	for index in 0 .. text_length + pattern_length {
		value := unsafe { packed[2 + index] }
		if value < 1 || value > 127 { return -1 }
	}
	if pattern_length == 0 { return 0 }
	if pattern_length > text_length { return -1 }

	pattern_start := 2 + text_length
	for start in 0 .. (text_length - pattern_length + 1) {
		mut offset := 0
		for offset < pattern_length && unsafe { packed[2 + start + offset] } == unsafe { packed[pattern_start + offset] } {
			offset++
		}
		if offset == pattern_length { return i64(start) }
	}
	return -1
}
