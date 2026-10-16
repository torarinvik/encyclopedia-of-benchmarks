package largest_smallest_words

import "core:c"

is_stripped_punctuation :: proc "contextless" (value: i64) -> bool {
	return value == 46 || value == 44 || value == 33 || value == 63 || value == 40 ||
		value == 41 || value == 91 || value == 93 || value == 123 || value == 125
}

put_u32 :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
	output[offset] = u8(value & 0xff)
	output[offset + 1] = u8((value >> 8) & 0xff)
	output[offset + 2] = u8((value >> 16) & 0xff)
	output[offset + 3] = u8((value >> 24) & 0xff)
}

@(export)
largest_smallest_words :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 515 || values[0] < 1 || values[0] > 512 ||
		length != c.size_t(1 + values[0]) { return -1 }
	text_length := int(values[0])
	text: [512]u8
	for index := 0; index < text_length; index += 1 {
		value := values[index + 1]
		if value < 32 || value > 126 { return -1 }
		text[index] = u8(value)
	}

	small_start := 0
	large_start := 0
	small_length := 513
	large_length := 0
	word_count := 0
	pos := 0
	for pos < text_length {
		for pos < text_length && text[pos] == u8(' ') { pos += 1 }
		if pos == text_length { break }
		token_start := pos
		for pos < text_length && text[pos] != u8(' ') { pos += 1 }
		first := token_start
		last := pos
		for first < last && is_stripped_punctuation(i64(text[first])) { first += 1 }
		for last > first && is_stripped_punctuation(i64(text[last - 1])) { last -= 1 }
		word_length := last - first
		if word_length < small_length { small_start = first; small_length = word_length }
		if word_length > large_length { large_start = first; large_length = word_length }
		word_count += 1
	}
	if word_count == 0 { return -1 }
	output_length := 8 + small_length + large_length
	if c.size_t(output_length) > output_capacity || output == nil { return -2 }
	put_u32(output, 0, u32(small_length))
	for index := 0; index < small_length; index += 1 { output[4 + index] = text[small_start + index] }
	large_header := 4 + small_length
	put_u32(output, large_header, u32(large_length))
	for index := 0; index < large_length; index += 1 {
		output[large_header + 4 + index] = text[large_start + index]
	}
	return i64(output_length)
}
