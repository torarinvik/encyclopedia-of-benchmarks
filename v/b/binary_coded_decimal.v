module binary_coded_decimal

// Write the prefixed four-bit-per-decimal-digit BCD representation.
@[export: 'binary_coded_decimal']
pub fn binary_coded_decimal(value i64, output &u8, output_capacity usize) i64 {
	if value < -2147483648 || value > 2147483647 { return -1 }
	mut normalized := value
	if normalized < 0 { normalized = 0 }

	mut digits := []u8{len: 10, init: 0}
	mut digit_count := 0
	mut remaining := normalized
	for remaining > 0 {
		digits[digit_count] = u8(remaining % 10)
		digit_count++
		remaining /= 10
	}
	if digit_count == 0 {
		digits[0] = 0
		digit_count = 1
	}

	output_length := usize(2 + digit_count * 4)
	if output_capacity < output_length { return -2 }
	unsafe {
		output[0] = u8(`0`)
		output[1] = u8(`b`)
	}
	mut position := usize(2)
	for digit_count > 0 {
		digit_count--
		digit := digits[digit_count]
		for bit := 3; bit >= 0; bit-- {
			unsafe { output[position] = u8(`0`) + ((digit >> u8(bit)) & 1) }
			position++
		}
	}
	return i64(output_length)
}
