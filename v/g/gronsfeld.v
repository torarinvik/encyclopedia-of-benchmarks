module gronsfeld

// Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
@[export: 'gronsfeld']
pub fn gronsfeld(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 321 { return -1 }
	if unsafe { input == nil } { return -1 }
	mut separator := usize(0)
	for separator < length && unsafe { input[separator] != 0 } { separator++ }
	if separator == length { return -1 }
	text_length := separator
	key_length := length - separator - 1
	if text_length > 256 || key_length < 1 || key_length > 64 { return -1 }

	for index := usize(0); index < text_length; index++ {
		value := unsafe { input[index] }
		if value < 1 || value > 127 { return -1 }
	}
	for index := usize(0); index < key_length; index++ {
		value := unsafe { input[separator + 1 + index] }
		if value < 48 || value > 57 { return -1 }
	}
	if output_capacity < text_length || (text_length > 0 && unsafe { output == nil }) { return -2 }

	mut key_index := usize(0)
	for index := usize(0); index < text_length; index++ {
		value := unsafe { input[index] }
		mut mapped := value
		if value >= 65 && value <= 90 {
			shift := unsafe { input[separator + 1 + key_index % key_length] } - 48
			mapped = 65 + (value - 65 + shift) % 26
			key_index++
		} else if value >= 97 && value <= 122 {
			shift := unsafe { input[separator + 1 + key_index % key_length] } - 48
			mapped = 97 + (value - 97 + shift) % 26
			key_index++
		}
		unsafe { output[index] = u8(mapped) }
	}
	return i64(text_length)
}
