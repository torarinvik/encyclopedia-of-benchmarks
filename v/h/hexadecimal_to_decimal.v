module hexadecimal_to_decimal

// Convert most-significant-first hexadecimal digits to a signed 64-bit value.
@[export: 'hexadecimal_to_decimal']
pub fn hexadecimal_to_decimal(digits &i64, length usize) i64 {
	if length == 0 || length > 16 { return -1 }
	if length == 16 && unsafe { digits[0] } > 7 { return -1 }
	mut result := i64(0)
	for index in 0 .. length {
		digit := unsafe { digits[index] }
		if digit < 0 || digit > 15 { return -1 }
		result = result * 16 + digit
	}
	return result
}
