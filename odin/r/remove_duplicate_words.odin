package remove_duplicate_words

import "core:c"

MAX_INPUT_LENGTH :: 4096
MAX_WORDS :: 2049

is_ascii_whitespace :: proc(byte: i64) -> bool {
	return byte == 32 || (byte >= 9 && byte <= 13)
}

@(export)
remove_duplicate_words :: proc "c" (values: [^]i64, length: c.size_t,
                                       output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > MAX_INPUT_LENGTH do return -1
	text_length := int(values[0])
	if length != c.size_t(text_length + 1) do return -1
	for index := 0; index < text_length; index += 1 {
		if values[index + 1] < 0 || values[index + 1] > 127 do return -1
	}

	starts: [MAX_WORDS]int
	word_lengths: [MAX_WORDS]int
	word_count := 0
	token_start := 0
	output_length := 0
	for boundary := 0; boundary <= text_length; boundary += 1 {
		if boundary < text_length && !is_ascii_whitespace(values[boundary + 1]) do continue
		word_length := boundary - token_start
		duplicate := false
		for previous := 0; previous < word_count && !duplicate; previous += 1 {
			if word_lengths[previous] != word_length do continue
			offset := 0
			for offset < word_length && values[1 + starts[previous] + offset] == values[1 + token_start + offset] { offset += 1 }
			duplicate = offset == word_length
		}
		if !duplicate {
			if word_count == MAX_WORDS do return -1
			starts[word_count] = token_start
			word_lengths[word_count] = word_length
			if word_count > 0 do output_length += 1
			output_length += word_length
			word_count += 1
		}
		if boundary < text_length do token_start = boundary + 1
	}
	if c.size_t(output_length) > output_capacity || (output_length > 0 && output == nil) do return -2

	written := 0
	for word := 0; word < word_count; word += 1 {
		if word > 0 { output[written] = 32; written += 1 }
		for offset := 0; offset < word_lengths[word]; offset += 1 {
			output[written] = u8(values[1 + starts[word] + offset])
			written += 1
		}
	}
	return i64(written)
}
