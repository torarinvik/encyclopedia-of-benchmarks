package translator

import "core:c"

MAX_KEYS :: 4
MAX_KEY_LENGTH :: 4
MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: 107
MAX_OUTPUT_LENGTH :: 256

translator :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 64 do return -1
	key_count, text_length := int(input[0]), int(input[1])
	keys: [MAX_KEYS][MAX_KEY_LENGTH]u8
	replacements: [MAX_KEYS][MAX_KEY_LENGTH]u8
	key_lengths, replacement_lengths: [MAX_KEYS]int
	cursor := 2
	for key_index := 0; key_index < key_count; key_index += 1 {
		if cursor + 2 > int(length) do return -1
		key_length_value, value_length_value := input[cursor], input[cursor + 1]
		cursor += 2
		if key_length_value < 1 || key_length_value > 4 || value_length_value < 0 || value_length_value > 4 do return -1
		key_length, value_length := int(key_length_value), int(value_length_value)
		if cursor + key_length + value_length > int(length) do return -1
		for index := 0; index < key_length; index += 1 {
			byte := input[cursor + index]
			if byte < 32 || byte > 126 do return -1
			keys[key_index][index] = u8(byte)
		}
		cursor += key_length
		for index := 0; index < value_length; index += 1 {
			byte := input[cursor + index]
			if byte < 32 || byte > 126 do return -1
			replacements[key_index][index] = u8(byte)
		}
		cursor += value_length
		key_lengths[key_index], replacement_lengths[key_index] = key_length, value_length
		for previous := 0; previous < key_index; previous += 1 {
			if key_lengths[previous] != key_length do continue
			equal := true
			for index := 0; index < key_length; index += 1 { if keys[previous][index] != keys[key_index][index] do equal = false }
			if equal do return -1
		}
	}
	if cursor + text_length != int(length) do return -1
	text: [MAX_TEXT_LENGTH]u8
	for index := 0; index < text_length; index += 1 {
		byte := input[cursor + index]
		if byte < 32 || byte > 126 do return -1
		text[index] = u8(byte)
	}
	result: [MAX_OUTPUT_LENGTH]u8
	result_length, start := 0, 0
	for start < text_length {
		matched := false
		maximum_length := min(MAX_KEY_LENGTH, text_length - start)
		for candidate_length := 1; candidate_length <= maximum_length && !matched; candidate_length += 1 {
			for key_index := 0; key_index < key_count; key_index += 1 {
				if key_lengths[key_index] != candidate_length do continue
				equal := true
				for index := 0; index < candidate_length; index += 1 { if text[start + index] != keys[key_index][index] do equal = false }
				if !equal do continue
				for index := 0; index < replacement_lengths[key_index]; index += 1 { result[result_length + index] = replacements[key_index][index] }
				result_length += replacement_lengths[key_index]
				start += candidate_length
				matched = true
				break
			}
		}
		if !matched do break
	}
	if output == nil || capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = result[index] }
	return i64(result_length)
}
