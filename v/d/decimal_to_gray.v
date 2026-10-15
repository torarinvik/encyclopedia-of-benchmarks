module decimal_to_gray

// Write the minimal-width ASCII binary form of n ^ (n >> 1).
@[export: 'decimal_to_gray']
pub fn decimal_to_gray(value i64, output &u8, output_capacity usize) i64 {
	if value < 0 { return -1 }
	gray := value ^ (value >> 1)
	mut width := usize(1)
	mut remaining := gray
	for remaining > 1 {
		remaining /= 2
		width++
	}
	if output_capacity < width { return -2 }

	mut position := width
	remaining = gray
	for position > 0 {
		position--
		unsafe { output[position] = u8(`0`) + u8(remaining % 2) }
		remaining /= 2
	}
	return i64(width)
}
