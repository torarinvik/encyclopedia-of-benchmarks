module decimal_to_binary

// Write the most-significant-first binary representation of a nonnegative i64.
@[export: 'decimal_to_binary']
pub fn decimal_to_binary(value i64, output &u8, output_capacity usize) i64 {
	if value < 0 { return -1 }
	mut width := usize(1)
	mut remaining := value
	for remaining > 1 {
		remaining /= 2
		width++
	}
	if output_capacity < width { return -2 }

	mut position := width
	remaining = value
	for position > 0 {
		position--
		unsafe { output[position] = u8(`0`) + u8(remaining % 2) }
		remaining /= 2
	}
	return i64(width)
}
