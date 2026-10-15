module vernam_cipher

const max_vernam_length = 1024

@[export: 'vernam_cipher']
pub fn vernam_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 3 || length > 2051 { return -1 }
	mode := unsafe { input[0] }
	text_length_value := unsafe { input[1] }
	key_length_value := unsafe { input[2] }
	if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > max_vernam_length || key_length_value < 1 || key_length_value > max_vernam_length { return -1 }
	text_length := int(text_length_value)
	key_length := int(key_length_value)
	if int(length) != 3 + text_length + key_length { return -1 }
	key_start := 3 + text_length
	for index in 0 .. text_length {
		value := unsafe { input[3 + index] }
		if value < 65 || value > 90 { return -1 }
	}
	for index in 0 .. key_length {
		value := unsafe { input[key_start + index] }
		if value < 65 || value > 90 { return -1 }
	}
	if output_capacity < usize(text_length) { return -2 }
	for index in 0 .. text_length {
		text_value := unsafe { input[3 + index] } - 65
		key_value := unsafe { input[key_start + index % key_length] } - 65
		mapped := if mode == 0 { (text_value + key_value) % 26 } else { (text_value - key_value + 26) % 26 }
		unsafe { output[index] = u8(65 + mapped) }
	}
	return i64(text_length)
}
