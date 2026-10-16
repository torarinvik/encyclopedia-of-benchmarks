module convert_to_negative

@[export: 'convert_to_negative']
pub fn convert_to_negative(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > 4096 { return -1 }
	if unsafe { values == nil } { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > 4095 || usize(count_value) != length - 1 { return -1 }
	count := int(count_value)
	for index in 0 .. count {
		channel := unsafe { values[index + 1] }
		if channel < 0 || channel > 255 { return -1 }
	}
	if usize(count) > output_capacity || (count != 0 && unsafe { output == nil }) { return -2 }
	unsafe {
		for index in 0 .. count { output[index] = u8(255 - values[index + 1]) }
	}
	return count_value
}
