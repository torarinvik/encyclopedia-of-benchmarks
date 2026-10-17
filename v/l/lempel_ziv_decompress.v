module lempel_ziv_decompress

const max_bit_count = 128
const max_parseable_input_length = 130
const max_output_bytes = 8256
const max_dictionary_entries = 130
const max_phrase_length = 129

@[export: 'lempel_ziv_decompress']
pub fn lempel_ziv_decompress(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > usize(max_parseable_input_length) { return -1 }
		bit_count_value := input[0]
		if bit_count_value < 0 || bit_count_value > max_bit_count { return -1 }
		bit_count := int(bit_count_value)
		if input_length != usize(1 + bit_count) { return -1 }
		for index in 0 .. bit_count {
			if input[index+1] != 48 && input[index+1] != 49 { return -1 }
		}

		mut codes := [max_dictionary_entries]int{}
		mut phrase_lengths := [max_dictionary_entries]int{}
		mut phrases := [max_dictionary_entries * max_phrase_length]u8{}
		codes[0], codes[1] = 0, 1
		phrase_lengths[0], phrase_lengths[1] = 1, 1
		phrases[0], phrases[max_phrase_length] = 48, 49
		mut entry_count, mut code_width, mut next_index := 2, 1, 2
		mut result := [max_output_bytes]u8{}
		mut result_length, mut cursor := 0, 0

		for cursor+code_width <= bit_count {
			code_width_used := code_width
			mut code := 0
			for bit_offset in 0 .. code_width_used {
				code = code*2 + int(input[cursor+bit_offset+1]-48)
			}
			mut found := entry_count
			for index in 0 .. entry_count {
				if codes[index] == code { found = index; break }
			}
			if found == entry_count { break }

			last_length := phrase_lengths[found]
			mut last_phrase := [max_phrase_length]u8{}
			for index in 0 .. last_length {
				value := phrases[found*max_phrase_length+index]
				last_phrase[index] = value
				result[result_length] = value
				result_length++
			}
			phrases[found*max_phrase_length+last_length] = 48
			phrase_lengths[found] = last_length+1

			if (next_index & (next_index-1)) == 0 {
				code_width++
			}
			codes[entry_count] = next_index
			phrase_lengths[entry_count] = last_length+1
			for index in 0 .. last_length {
				phrases[entry_count*max_phrase_length+index] = last_phrase[index]
			}
			phrases[entry_count*max_phrase_length+last_length] = 49
			entry_count++
			next_index++
			cursor += code_width_used
		}
		if output == nil || output_capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length { output[index] = result[index] }
		return i64(result_length)
	}
}
