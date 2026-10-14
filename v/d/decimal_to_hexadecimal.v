module decimal_to_hexadecimal

// Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
@[export: 'decimal_to_hexadecimal']
pub fn decimal_to_hexadecimal(value i64, output &u8, output_capacity usize) i64 {
	if value < 0 { return -1 }
	mut width := usize(1)
	mut remaining := value
	for remaining >= 16 {
		remaining /= 16
		width++
	}
	if output_capacity < width { return -2 }
	mut position := width
	remaining = value
	for position > 0 {
		position--
		digit := remaining % 16
		if digit < 10 { unsafe { output[position] = u8(`0`) + u8(digit) } }
		else { unsafe { output[position] = u8(`a`) + u8(digit - 10) } }
		remaining /= 16
	}
	return i64(width)
}
