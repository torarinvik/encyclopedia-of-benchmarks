module count_letters

fn lowercase_ascii_letter(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'count_letters']
pub fn count_letters(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	if unsafe { input[1] } < 0 || unsafe { input[1] } > 256 { return -1 }
	text_length := int(unsafe { input[1] })
	if int(length) != text_length + 2 { return -1 }
	query := lowercase_ascii_letter(unsafe { input[0] })
	if query < 97 || query > 122 { return -1 }
	mut count := i64(0)
	for index in 0 .. text_length {
		value := unsafe { input[index + 2] }
		if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) { return -1 }
		if lowercase_ascii_letter(value) == query { count++ }
	}
	return count
}
