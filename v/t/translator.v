module translator

const max_keys = 4
const max_key_length = 4
const max_text_length = 64
const max_input_length = 107
const max_output_length = 256

@[export: 'translator']
pub fn translator(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_keys || input[1] < 0 || input[1] > max_text_length { return -1 }
		key_count, text_length := int(input[0]), int(input[1])
		mut keys := [max_keys][max_key_length]u8{}
		mut replacements := [max_keys][max_key_length]u8{}
		mut key_lengths := [max_keys]int{}
		mut replacement_lengths := [max_keys]int{}
		mut cursor := 2
		for key_index := 0; key_index < key_count; key_index++ {
			if cursor + 2 > int(length) { return -1 }
			key_length_value, value_length_value := input[cursor], input[cursor + 1]
			cursor += 2
			if key_length_value < 1 || key_length_value > max_key_length || value_length_value < 0 || value_length_value > max_key_length { return -1 }
			key_length, value_length := int(key_length_value), int(value_length_value)
			if cursor + key_length + value_length > int(length) { return -1 }
			for index := 0; index < key_length; index++ {
				byte := input[cursor + index]
				if byte < 32 || byte > 126 { return -1 }
				keys[key_index][index] = u8(byte)
			}
			cursor += key_length
			for index := 0; index < value_length; index++ {
				byte := input[cursor + index]
				if byte < 32 || byte > 126 { return -1 }
				replacements[key_index][index] = u8(byte)
			}
			cursor += value_length
			key_lengths[key_index], replacement_lengths[key_index] = key_length, value_length
			for previous := 0; previous < key_index; previous++ {
				if key_lengths[previous] != key_length { continue }
				equal := true
				for index := 0; index < key_length; index++ { if keys[previous][index] != keys[key_index][index] { equal = false } }
				if equal { return -1 }
			}
		}
		if cursor + text_length != int(length) { return -1 }
		mut text := [max_text_length]u8{}
		for index := 0; index < text_length; index++ {
			byte := input[cursor + index]
			if byte < 32 || byte > 126 { return -1 }
			text[index] = u8(byte)
		}
		mut result := [max_output_length]u8{}
		mut result_length, mut start := 0, 0
		for start < text_length {
			mut matched := false
			maximum_length := if text_length - start < max_key_length { text_length - start } else { max_key_length }
			for candidate_length := 1; candidate_length <= maximum_length && !matched; candidate_length++ {
				for key_index := 0; key_index < key_count; key_index++ {
					if key_lengths[key_index] != candidate_length { continue }
					mut equal := true
					for index := 0; index < candidate_length; index++ { if text[start + index] != keys[key_index][index] { equal = false } }
					if !equal { continue }
					for index := 0; index < replacement_lengths[key_index]; index++ { result[result_length + index] = replacements[key_index][index] }
					result_length += replacement_lengths[key_index]
					start += candidate_length
					matched = true
					break
				}
			}
			if !matched { break }
		}
		if unsafe { output == nil } || capacity < result_length { return -2 }
		for index := 0; index < result_length; index++ { output[index] = result[index] }
		return i64(result_length)
	}
}
