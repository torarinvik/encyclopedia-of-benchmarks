package lempel_ziv_decompress

import "core:c"

MAX_BIT_COUNT :: 128
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(130)
MAX_OUTPUT_BYTES :: 8256
MAX_DICTIONARY_ENTRIES :: 130
MAX_PHRASE_LENGTH :: 129

lempel_ziv_decompress :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	bit_count_value := input[0]
	if bit_count_value < 0 || bit_count_value > MAX_BIT_COUNT do return -1
	bit_count := int(bit_count_value)
	if input_length != c.size_t(1+bit_count) do return -1
	for index := 0; index < bit_count; index += 1 {
		if input[index+1] != 48 && input[index+1] != 49 do return -1
	}

	codes: [MAX_DICTIONARY_ENTRIES]usize
	phrase_lengths: [MAX_DICTIONARY_ENTRIES]usize
	phrases: [MAX_DICTIONARY_ENTRIES*MAX_PHRASE_LENGTH]u8
	codes[0], codes[1] = 0, 1
	phrase_lengths[0], phrase_lengths[1] = 1, 1
	phrases[0], phrases[MAX_PHRASE_LENGTH] = 48, 49
	entry_count, code_width, next_index := 2, 1, 2
	result: [MAX_OUTPUT_BYTES]u8
	result_length, cursor := 0, 0

	for cursor+code_width <= bit_count {
		code_width_used := code_width
		code := 0
		for bit_offset := 0; bit_offset < code_width; bit_offset += 1 {
			code = code*2 + int(input[cursor+bit_offset+1]-48)
		}
		found := entry_count
		for index := 0; index < entry_count; index += 1 {
			if codes[index] == usize(code) { found = index; break }
		}
		if found == entry_count do break

		last_length := phrase_lengths[found]
		last_phrase: [MAX_PHRASE_LENGTH]u8
		for index := 0; index < last_length; index += 1 {
			value := phrases[found*MAX_PHRASE_LENGTH+index]
			last_phrase[index] = value
			result[result_length] = value
			result_length += 1
		}
		phrases[found*MAX_PHRASE_LENGTH+last_length] = 48
		phrase_lengths[found] = last_length+1

		if (next_index & (next_index-1)) == 0 {
			code_width += 1
		}
		codes[entry_count] = usize(next_index)
		phrase_lengths[entry_count] = last_length+1
		for index := 0; index < last_length; index += 1 {
			phrases[entry_count*MAX_PHRASE_LENGTH+index] = last_phrase[index]
		}
		phrases[entry_count*MAX_PHRASE_LENGTH+last_length] = 49
		entry_count += 1
		next_index += 1
		cursor += code_width_used
	}
	if output == nil || output_capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = result[index] }
	return i64(result_length)
}
