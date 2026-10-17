package lempel_ziv

import "core:c"

MAX_BIT_COUNT :: 128
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(130)
MAX_OUTPUT_BYTES :: 1032
MAX_DICTIONARY_ENTRIES :: 130
MAX_KEY_LENGTH :: 129
MAX_CODE_WIDTH :: 8

lempel_ziv :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	bit_count_value := input[0]
	if bit_count_value < 0 || bit_count_value > MAX_BIT_COUNT do return -1
	bit_count := int(bit_count_value)
	if input_length != c.size_t(1+bit_count) do return -1
	for index := 0; index < bit_count; index += 1 {
		if input[index+1] != 48 && input[index+1] != 49 do return -1
	}

	keys: [MAX_DICTIONARY_ENTRIES*MAX_KEY_LENGTH]u8
	key_lengths: [MAX_DICTIONARY_ENTRIES]int
	codes: [MAX_DICTIONARY_ENTRIES*MAX_CODE_WIDTH]u8
	code_lengths: [MAX_DICTIONARY_ENTRIES]int
	keys[0], keys[MAX_KEY_LENGTH] = 48, 49
	key_lengths[0], key_lengths[1] = 1, 1
	codes[0], codes[MAX_CODE_WIDTH] = 48, 49
	code_lengths[0], code_lengths[1] = 1, 1
	entry_count, next_index := 2, 2
	current: [MAX_KEY_LENGTH]u8
	current_length := 0
	result: [MAX_OUTPUT_BYTES]u8
	result_length := 0

	for input_index := 0; input_index < bit_count; input_index += 1 {
		current[current_length] = u8(input[input_index+1])
		current_length += 1
		found := entry_count
		for entry := 0; entry < entry_count; entry += 1 {
			if key_lengths[entry] == current_length {
				matched := true
				for component := 0; component < current_length; component += 1 {
					if keys[entry*MAX_KEY_LENGTH+component] != current[component] { matched = false; break }
				}
				if matched { found = entry; break }
			}
		}
		if found == entry_count do continue

		last_code_length := code_lengths[found]
		last_code: [MAX_CODE_WIDTH]u8
		for component := 0; component < last_code_length; component += 1 {
			last_code[component] = codes[found*MAX_CODE_WIDTH+component]
			result[result_length] = last_code[component]
			result_length += 1
		}
		for entry := found; entry < entry_count-1; entry += 1 {
			for component := 0; component < MAX_KEY_LENGTH; component += 1 {
				keys[entry*MAX_KEY_LENGTH+component] = keys[(entry+1)*MAX_KEY_LENGTH+component]
			}
			for component := 0; component < MAX_CODE_WIDTH; component += 1 {
				codes[entry*MAX_CODE_WIDTH+component] = codes[(entry+1)*MAX_CODE_WIDTH+component]
			}
			key_lengths[entry] = key_lengths[entry+1]
			code_lengths[entry] = code_lengths[entry+1]
		}
		entry_count -= 1
		for component := 0; component < current_length; component += 1 { keys[entry_count*MAX_KEY_LENGTH+component] = current[component] }
		keys[entry_count*MAX_KEY_LENGTH+current_length] = 48
		key_lengths[entry_count] = current_length+1
		for component := 0; component < last_code_length; component += 1 { codes[entry_count*MAX_CODE_WIDTH+component] = last_code[component] }
		code_lengths[entry_count] = last_code_length
		entry_count += 1

		if (next_index & (next_index-1)) == 0 {
			for entry := 0; entry < entry_count; entry += 1 {
				code_length := code_lengths[entry]
				for component := code_length; component > 0; component -= 1 { codes[entry*MAX_CODE_WIDTH+component] = codes[entry*MAX_CODE_WIDTH+component-1] }
				codes[entry*MAX_CODE_WIDTH] = 48
				code_lengths[entry] = code_length+1
			}
		}
		for component := 0; component < current_length; component += 1 { keys[entry_count*MAX_KEY_LENGTH+component] = current[component] }
		keys[entry_count*MAX_KEY_LENGTH+current_length] = 49
		key_lengths[entry_count] = current_length+1
		code_width, temp := 1, next_index
		for temp > 1 { temp /= 2; code_width += 1 }
		code_lengths[entry_count] = code_width
		for component := 0; component < code_width; component += 1 {
			bit := (next_index >> (code_width-component-1)) & 1
			codes[entry_count*MAX_CODE_WIDTH+component] = u8(48+bit)
		}
		entry_count += 1
		next_index += 1
		current_length = 0
	}

	if current_length > 0 {
		max_key_length := 0
		for entry := 0; entry < entry_count; entry += 1 { if key_lengths[entry] > max_key_length { max_key_length = key_lengths[entry] } }
		found := entry_count
		for found == entry_count {
			for entry := 0; entry < entry_count; entry += 1 {
				if key_lengths[entry] == current_length {
					matched := true
					for component := 0; component < current_length; component += 1 {
						if keys[entry*MAX_KEY_LENGTH+component] != current[component] { matched = false; break }
					}
					if matched { found = entry; break }
				}
			}
			if found == entry_count {
				if current_length >= max_key_length { break }
				current[current_length] = 48
				current_length += 1
			}
		}
		if found == entry_count do return -1
		for component := 0; component < code_lengths[found]; component += 1 {
			result[result_length] = codes[found*MAX_CODE_WIDTH+component]
			result_length += 1
		}
	}
	if output == nil || output_capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = result[index] }
	return i64(result_length)
}
