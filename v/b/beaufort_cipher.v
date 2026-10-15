module beaufort_cipher

@[export: 'beaufort_cipher']
pub fn beaufort_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > 2051 || unsafe { input == nil } { return -1 }
	unsafe {
		mode := input[0]
		text_value := input[1]
		key_value := input[2]
		if (mode != 0 && mode != 1) || text_value < 0 || text_value > 1024 || key_value < 0 || key_value > 1024 { return -1 }
		text_length := int(text_value)
		key_length := int(key_value)
		if int(length) != 3 + text_length + key_length ||
			(text_length == 0 && key_length != 0) ||
			(text_length != 0 && (key_length == 0 || key_length > text_length)) { return -1 }
		key_start := 3 + text_length
		for index in 0 .. text_length {
			value := input[3 + index]
			if value != 32 && (value < 65 || value > 90) { return -1 }
		}
		for index in 0 .. key_length {
			if input[key_start + index] < 65 || input[key_start + index] > 90 { return -1 }
		}
		if output_capacity < usize(text_length) || (text_length > 0 && output == nil) { return -2 }
		mut key_index := 0
		for index in 0 .. text_length {
			value := input[3 + index]
			if value == 32 { output[index] = 32; continue }
			letter := value - 65
			key_letter := input[key_start + key_index % key_length] - 65
			mapped := if mode == 0 { (letter - key_letter + 26) % 26 } else { (letter + key_letter) % 26 }
			output[index] = u8(65 + mapped)
			key_index++
		}
		return i64(text_length)
	}
}
