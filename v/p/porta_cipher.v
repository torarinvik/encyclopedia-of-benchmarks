module porta_cipher

@[export: 'porta_cipher']
pub fn porta_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > 1091 || unsafe { input == nil } { return -1 }
	unsafe {
		mode := input[0]
		text_value := input[1]
		key_value := input[2]
		if (mode != 0 && mode != 1) || text_value < 0 || text_value > 1024 || key_value < 0 || key_value > 64 { return -1 }
		text_length := int(text_value)
		key_length := int(key_value)
		if int(length) != 3 + text_length + key_length || (text_length > 0 && key_length == 0) { return -1 }
		key_start := 3 + text_length
		for index in 3 .. int(length) {
			value := input[index]
			if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
		}
		if output_capacity < usize(text_length) || (text_length > 0 && output == nil) { return -2 }
		for index in 0 .. text_length {
			mut letter := input[3 + index]
			mut key_letter := input[key_start + index % key_length]
			if letter >= 97 { letter -= 32 }
			if key_letter >= 97 { key_letter -= 32 }
			letter_index := letter - 65
			group := (key_letter - 65) / 2
			mapped := if letter_index < 13 { 13 + (letter_index + 13 - group) % 13 } else { (letter_index - 13 + group) % 13 }
			output[index] = u8(65 + mapped)
		}
		return i64(text_length)
	}
}
