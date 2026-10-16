module wave_string

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@[export: 'wave_string']
pub fn wave_string(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || isnil(values) { return -1 }
	text_value := unsafe { values[0] }
	if text_value < 0 || text_value > 512 || length != usize(1 + text_value) { return -1 }
	text_length := int(text_value)
	mut letter_count := 0
	for index in 0 .. text_length {
		byte := unsafe { values[index + 1] }
		if byte < 32 || byte > 126 { return -1 }
		if is_ascii_letter(byte) { letter_count++ }
	}
	output_length := letter_count * (text_length + 2)
	if usize(output_length) > output_capacity || (output_length > 0 && isnil(output)) { return -2 }

	mut written := 0
	for position in 0 .. text_length {
		if !is_ascii_letter(unsafe { values[position + 1] }) { continue }
		unsafe {
			output[written] = u8(text_length & 255)
			output[written + 1] = u8(text_length >> 8)
		}
		written += 2
		for index in 0 .. text_length {
			mut byte := unsafe { values[index + 1] }
			if index == position && byte >= 97 && byte <= 122 { byte -= 32 }
			unsafe { output[written] = u8(byte) }
			written++
		}
	}
	return i64(letter_count)
}
