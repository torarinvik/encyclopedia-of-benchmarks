package remove_duplicate

import "core:c"

compare_words :: proc "contextless" (values: [^]i64, start_a, length_a, start_b, length_b: int) -> int {
	common := length_a
	if length_b < common { common = length_b }
	for index := 0; index < common; index += 1 {
		a := values[1 + start_a + index]
		b := values[1 + start_b + index]
		if a < b { return -1 }
		if a > b { return 1 }
	}
	if length_a < length_b { return -1 }
	if length_a > length_b { return 1 }
	return 0
}

@(export)
remove_duplicate :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > 1024 ||
		length != c.size_t(1 + values[0]) { return -1 }
	text_length := int(values[0])
	for index := 0; index < text_length; index += 1 {
		byte := values[index + 1]
		if byte != 32 && (byte < 97 || byte > 122) { return -1 }
	}
	starts: [512]int
	word_lengths: [512]int
	word_count := 0
	cursor := 0
	for cursor < text_length {
		if values[cursor + 1] == 32 { cursor += 1; continue }
		starts[word_count] = cursor
		for cursor < text_length && values[cursor + 1] != 32 { cursor += 1 }
		word_lengths[word_count] = cursor - starts[word_count]
		word_count += 1
	}
	for index := 1; index < word_count; index += 1 {
		key_start := starts[index]
		key_length := word_lengths[index]
		position := index
		for position > 0 && compare_words(values, starts[position - 1], word_lengths[position - 1], key_start, key_length) > 0 {
			starts[position] = starts[position - 1]
			word_lengths[position] = word_lengths[position - 1]
			position -= 1
		}
		starts[position] = key_start
		word_lengths[position] = key_length
	}
	output_length := 0
	unique_count := 0
	for index := 0; index < word_count; index += 1 {
		if index > 0 && compare_words(values, starts[index - 1], word_lengths[index - 1], starts[index], word_lengths[index]) == 0 { continue }
		if unique_count > 0 { output_length += 1 }
		output_length += word_lengths[index]
		unique_count += 1
	}
	if output_length > int(output_capacity) || (output_length > 0 && output == nil) { return -2 }
	written := 0
	emitted := 0
	for index := 0; index < word_count; index += 1 {
		if index > 0 && compare_words(values, starts[index - 1], word_lengths[index - 1], starts[index], word_lengths[index]) == 0 { continue }
		if emitted > 0 { output[written] = 32; written += 1 }
		for byte := 0; byte < word_lengths[index]; byte += 1 {
			output[written] = u8(values[1 + starts[index] + byte])
			written += 1
		}
		emitted += 1
	}
	return i64(output_length)
}
