module decimal_to_octal

// Write the octal digits of a nonnegative signed 64-bit input.
@[export: 'decimal_to_octal']
pub fn decimal_to_octal(value i64, output &u8, output_capacity usize) i64 {
	if value < 0 { return -1 }
	mut width := usize(1)
	mut remaining := value
	for remaining >= 8 {
		remaining /= 8
		width++
	}
	if output_capacity < width { return -2 }
	mut position := width
	remaining = value
	for position > 0 {
		position--
		unsafe { output[position] = u8(`0`) + u8(remaining % 8) }
		remaining /= 8
	}
	return i64(width)
}
