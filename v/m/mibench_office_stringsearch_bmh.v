module mibench_office_stringsearch_bmh

// Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
const max_text = 128
const max_pattern = 32
const max_input = 162

@[export: 'mibench_office_stringsearch_bmh']
pub fn mibench_office_stringsearch_bmh(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if input == nil || length < 2 || length > max_input { return -1 }
	text_len_value := unsafe { input[0] }
	pattern_len_value := unsafe { input[1] }
	if text_len_value < 0 || text_len_value > max_text ||
		pattern_len_value < 1 || pattern_len_value > max_pattern { return -1 }
	text_len := int(text_len_value)
	pattern_len := int(pattern_len_value)
	if length != usize(2 + text_len + pattern_len) { return -1 }
	mut text := [max_text]u8{}
	mut pattern := [max_pattern]u8{}
	for i in 0 .. text_len + pattern_len {
		value := unsafe { input[2 + i] }
		if value < 32 || value > 126 { return -1 }
		if i < text_len { text[i] = u8(value) } else { pattern[i - text_len] = u8(value) }
	}
	mut shift := [256]int{}
	for i in 0 .. 256 { shift[i] = pattern_len }
	for i in 0 .. pattern_len - 1 { shift[int(pattern[i])] = pattern_len - i - 1 }
	mut match_offset := i64(-1)
	if pattern_len <= text_len {
		mut start := 0
		for start <= text_len - pattern_len {
			mut j := pattern_len
			for j > 0 && text[start + j - 1] == pattern[j - 1] { j-- }
			if j == 0 { match_offset = i64(start); break }
			start += shift[int(text[start + pattern_len - 1])]
		}
	}
	if output == nil || output_capacity < 8 { return -2 }
	bits := u64(match_offset)
	for i in 0 .. 8 { unsafe { output[i] = u8((bits >> (8 * i)) & 255) } }
	return 8
}
