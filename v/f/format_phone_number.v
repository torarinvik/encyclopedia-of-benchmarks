module format_phone_number

@[export: 'format_phone_number']
pub fn format_phone_number(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 10 { return -1 }
	if unsafe { values == nil } { return -1 }
	for i in 0 .. 10 {
		digit := unsafe { values[i] }
		if digit < 48 || digit > 57 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < 14 { return -2 }

	unsafe {
		output[0] = 40
		for i in 0 .. 3 { output[i + 1] = u8(values[i]) }
		output[4] = 41
		output[5] = 32
		for i in 0 .. 3 { output[i + 6] = u8(values[i + 3]) }
		output[9] = 45
		for i in 0 .. 4 { output[i + 10] = u8(values[i + 6]) }
	}
	return 14
}
