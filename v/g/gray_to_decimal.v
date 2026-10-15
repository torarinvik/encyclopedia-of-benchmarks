module gray_to_decimal

@[export: 'gray_to_decimal']
pub fn gray_to_decimal(values &i64, length usize) i64 {
	if length < 2 || length > 64 { return -1 }
	bit_length := unsafe { values[0] }
	if bit_length < 1 || bit_length > 63 || length != usize(bit_length + 1) { return -1 }

	mut prefix := i64(0)
	mut binary := i64(0)
	for index in 1 .. length {
		character := unsafe { values[index] }
		if character != 48 && character != 49 { return -1 }
		prefix ^= character - 48
		binary = binary * 2 + prefix
	}
	return binary
}
