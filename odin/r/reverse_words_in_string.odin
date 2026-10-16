package reverse_words_in_string

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 258

is_trim_byte :: proc "contextless" (value: i64) -> bool { return value >= 0 && value <= 32 }
is_split_space :: proc "contextless" (value: i64) -> bool { return value == 32 || (value >= 9 && value <= 13) }

@(export)
reverse_words_in_string :: proc "c" (input: [^]i64, length: c.size_t,
                                      output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > 256 do return -1
	text_length := int(input[0])
	if int(length) != text_length + 1 do return -1
	for i := 0; i < text_length; i += 1 {
		if input[i + 1] < 0 || input[i + 1] > 127 do return -1
	}

	start := 0
	end := text_length
	for start < end && is_trim_byte(input[start + 1]) do start += 1
	for end > start && is_trim_byte(input[end]) do end -= 1

	output_length := 0
	word_count := 0
	position := start
	for position < end {
		for position < end && is_split_space(input[position + 1]) do position += 1
		if position < end {
			token_start := position
			for position < end && !is_split_space(input[position + 1]) do position += 1
			output_length += position - token_start
			if word_count > 0 do output_length += 1
			word_count += 1
		}
	}
	if capacity < output_length || (output_length > 0 && output == nil) do return -2

	written := 0
	emitted := 0
	position = end
	for position > start {
		for position > start && is_split_space(input[position]) do position -= 1
		if position > start {
			token_end := position
			for position > start && !is_split_space(input[position]) do position -= 1
			token_start := position
			if emitted > 0 { output[written] = u8(32); written += 1 }
			for i := token_start; i < token_end; i += 1 {
				output[written] = u8(input[i + 1])
				written += 1
			}
			emitted += 1
		}
	}
	return i64(written)
}
