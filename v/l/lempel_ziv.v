module lempel_ziv

const max_bit_count = 128
const max_parseable_input_length = 130
const max_output_bytes = 1032
const max_dictionary_entries = 130
const max_key_length = 129
const max_code_width = 8

@[export: 'lempel_ziv']
pub fn lempel_ziv(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > usize(max_parseable_input_length) { return -1 }
		bit_count_value := input[0]
		if bit_count_value < 0 || bit_count_value > max_bit_count { return -1 }
		bit_count := int(bit_count_value)
		if input_length != usize(1+bit_count) { return -1 }
		for index in 0 .. bit_count { if input[index+1] != 48 && input[index+1] != 49 { return -1 } }

		mut keys := [max_dictionary_entries * max_key_length]u8{}
		mut key_lengths := [max_dictionary_entries]int{}
		mut codes := [max_dictionary_entries * max_code_width]u8{}
		mut code_lengths := [max_dictionary_entries]int{}
		keys[0], keys[max_key_length] = 48, 49
		key_lengths[0], key_lengths[1] = 1, 1
		codes[0], codes[max_code_width] = 48, 49
		code_lengths[0], code_lengths[1] = 1, 1
		mut entry_count, mut next_index := 2, 2
		mut current := [max_key_length]u8{}
		mut current_length := 0
		mut result := [max_output_bytes]u8{}
		mut result_length := 0

		for input_index in 0 .. bit_count {
			current[current_length] = u8(input[input_index+1])
			current_length++
			mut found := entry_count
			for entry in 0 .. entry_count {
				if key_lengths[entry] == current_length {
					mut matched := true
					for component in 0 .. current_length {
						if keys[entry*max_key_length+component] != current[component] { matched = false; break }
					}
					if matched { found = entry; break }
				}
			}
			if found == entry_count { continue }

			last_code_length := code_lengths[found]
			mut last_code := [max_code_width]u8{}
			for component in 0 .. last_code_length {
				last_code[component] = codes[found*max_code_width+component]
				result[result_length] = last_code[component]
				result_length++
			}
			for entry in found .. entry_count-1 {
				for component in 0 .. max_key_length { keys[entry*max_key_length+component] = keys[(entry+1)*max_key_length+component] }
				for component in 0 .. max_code_width { codes[entry*max_code_width+component] = codes[(entry+1)*max_code_width+component] }
				key_lengths[entry] = key_lengths[entry+1]
				code_lengths[entry] = code_lengths[entry+1]
			}
			entry_count--
			for component in 0 .. current_length { keys[entry_count*max_key_length+component] = current[component] }
			keys[entry_count*max_key_length+current_length] = 48
			key_lengths[entry_count] = current_length+1
			for component in 0 .. last_code_length { codes[entry_count*max_code_width+component] = last_code[component] }
			code_lengths[entry_count] = last_code_length
			entry_count++

			if (next_index & (next_index-1)) == 0 {
				for entry in 0 .. entry_count {
					code_length := code_lengths[entry]
					for component := code_length; component > 0; component-- { codes[entry*max_code_width+component] = codes[entry*max_code_width+component-1] }
					codes[entry*max_code_width] = 48
					code_lengths[entry] = code_length+1
				}
			}
			for component in 0 .. current_length { keys[entry_count*max_key_length+component] = current[component] }
			keys[entry_count*max_key_length+current_length] = 49
			key_lengths[entry_count] = current_length+1
			mut code_width, mut temp := 1, next_index
			for temp > 1 { temp /= 2; code_width++ }
			code_lengths[entry_count] = code_width
			for component in 0 .. code_width {
				bit := (next_index >> (code_width-component-1)) & 1
				codes[entry_count*max_code_width+component] = u8(48+bit)
			}
			entry_count++
			next_index++
			current_length = 0
		}

		if current_length > 0 {
			mut max_key_len := 0
			for entry in 0 .. entry_count { if key_lengths[entry] > max_key_len { max_key_len = key_lengths[entry] } }
			mut found := entry_count
			for found == entry_count {
				for entry in 0 .. entry_count {
					if key_lengths[entry] == current_length {
						mut matched := true
						for component in 0 .. current_length { if keys[entry*max_key_length+component] != current[component] { matched = false; break } }
						if matched { found = entry; break }
					}
				}
				if found == entry_count {
					if current_length >= max_key_len { break }
					current[current_length] = 48
					current_length++
				}
			}
			if found == entry_count { return -1 }
			for component in 0 .. code_lengths[found] { result[result_length] = codes[found*max_code_width+component]; result_length++ }
		}
		if output == nil || output_capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length { output[index] = result[index] }
		return i64(result_length)
	}
}
