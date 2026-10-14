module octal_to_decimal

// Convert most-significant-first octal digits to a signed 64-bit value.
@[export: 'octal_to_decimal']
pub fn octal_to_decimal(digits &i64, length usize) i64 {
	if length == 0 || length > 21 { return -1 }
	mut result := i64(0)
	for index in 0 .. length {
		digit := unsafe { digits[index] }
		if digit < 0 || digit > 7 { return -1 }
		result = result * 8 + digit
	}
	return result
}
