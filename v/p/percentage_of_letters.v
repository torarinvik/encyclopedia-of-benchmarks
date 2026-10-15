module percentage_of_letters

fn lower_ascii(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'percentage_of_letters']
pub fn percentage_of_letters(values &i64, length usize) i64 {
	if length < 2 || length > 4097 || unsafe { values == nil } { return -1 }
	unsafe {
		target := lower_ascii(values[0])
		if target < 97 || target > 122 { return -1 }
		text_length := int(length) - 1
		mut matches := 0
		for index in 0 .. text_length {
			value := values[index + 1]
			if value < 0 || value > 127 { return -1 }
			if lower_ascii(value) == target { matches++ }
		}
		return i64((100 * matches) / text_length)
	}
}
