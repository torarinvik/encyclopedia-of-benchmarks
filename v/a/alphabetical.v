module alphabetical

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

fn lowercase_ascii(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'alphabetical']
pub fn alphabetical(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	mut index := usize(0)
	for index < length {
		value := unsafe { values[index] }
		if value < 0 || value > 127 { return -1 }
		index++
	}
	if length == 0 { return 0 }
	mut previous := i64(-1)
	index = 0
	for index < length {
		value := unsafe { values[index] }
		if !is_ascii_letter(value) { return 0 }
		current := lowercase_ascii(value)
		if current < previous { return 0 }
		previous = current
		index++
	}
	return 1
}
