module autokey_cipher

const max_autokey_length = 1024

fn uppercase_letter(value i64) i64 {
	if value >= 97 && value <= 122 { return value - 32 }
	return value
}

@[export: 'autokey_cipher']
pub fn autokey_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 6 || length > 2052 { return -1 }
	mode := unsafe { input[0] }
	dialect := unsafe { input[1] }
	text_length_value := unsafe { input[2] }
	key_length_value := unsafe { input[3] }
	if (mode != 0 && mode != 1) || (dialect != 0 && dialect != 1) || text_length_value < 1 || text_length_value > max_autokey_length || key_length_value < 1 || key_length_value > max_autokey_length { return -1 }
	text_length := int(text_length_value)
	key_length := int(key_length_value)
	if int(length) != 4 + text_length + key_length { return -1 }
	key_start := 4 + text_length
	for index in 0 .. text_length {
		value := unsafe { input[4 + index] }
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
		if dialect == 1 && mode == 1 && value >= 65 && value <= 90 { return -1 }
	}
	for index in 0 .. key_length {
		value := unsafe { input[key_start + index] }
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
	}
	if output_capacity < usize(text_length) || output == nil { return -2 }
	for index in 0 .. text_length {
		plain := uppercase_letter(unsafe { input[4 + index] }) - 65
		mut key_value := i64(0)
		if index < key_length { key_value = uppercase_letter(unsafe { input[key_start + index] }) }
		else if mode == 0 { key_value = uppercase_letter(unsafe { input[4 + index - key_length] }) }
		else { key_value = uppercase_letter(i64(unsafe { output[index - key_length] })) }
		shift := key_value - 65
		mut mapped := (plain + shift) % 26
		if mode == 1 { mapped = (plain - shift + 26) % 26 }
		mut result := 65 + mapped
		if dialect == 1 { result += 32 }
		unsafe { output[index] = u8(result) }
	}
	return i64(text_length)
}
