module largest_smallest_words

fn is_stripped_punctuation(value u8) bool {
	return value == `.` || value == `,` || value == `!` || value == `?` || value == `(` ||
		value == `)` || value == `[` || value == `]` || value == `{` || value == `}`
}

fn put_u32(mut output &u8, offset int, value u32) {
	unsafe {
		output[offset] = u8(value & 0xff)
		output[offset + 1] = u8((value >> 8) & 0xff)
		output[offset + 2] = u8((value >> 16) & 0xff)
		output[offset + 3] = u8((value >> 24) & 0xff)
	}
}

@[export: 'largest_smallest_words']
pub fn largest_smallest_words(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || length > 515 || isnil(values) { return -1 }
	text_value := unsafe { values[0] }
	if text_value < 1 || text_value > 512 || length != usize(1 + text_value) { return -1 }
	text_length := int(text_value)
	mut text := []u8{len: text_length, cap: text_length}
	for index in 0 .. text_length {
		value := unsafe { values[index + 1] }
		if value < 32 || value > 126 { return -1 }
		text[index] = u8(value)
	}

	mut small_start := 0
	mut large_start := 0
	mut small_length := 513
	mut large_length := 0
	mut word_count := 0
	mut pos := 0
	for pos < text_length {
		for pos < text_length && text[pos] == ` ` { pos++ }
		if pos == text_length { break }
		token_start := pos
		for pos < text_length && text[pos] != ` ` { pos++ }
		mut first := token_start
		mut last := pos
		for first < last && is_stripped_punctuation(text[first]) { first++ }
		for last > first && is_stripped_punctuation(text[last - 1]) { last-- }
		word_length := last - first
		if word_length < small_length { small_start = first; small_length = word_length }
		if word_length > large_length { large_start = first; large_length = word_length }
		word_count++
	}
	if word_count == 0 { return -1 }
	output_length := 8 + small_length + large_length
	if output_length > output_capacity || isnil(output) { return -2 }
	put_u32(mut output, 0, u32(small_length))
	unsafe {
		for index in 0 .. small_length { output[4 + index] = text[small_start + index] }
	}
	large_header := 4 + small_length
	put_u32(mut output, large_header, u32(large_length))
	unsafe {
		for index in 0 .. large_length { output[large_header + 4 + index] = text[large_start + index] }
	}
	return i64(output_length)
}
