module binary_to_decimal

// Convert most-significant-first binary digits to a signed 64-bit decimal value.
@[export: 'binary_to_decimal']
pub fn binary_to_decimal(bits &i64, length usize) i64 {
	if length == 0 || length > 63 { return -1 }
	mut value := u64(0)
	for index in 0 .. length {
		bit := unsafe { bits[index] }
		if bit != 0 && bit != 1 { return -1 }
		value = value * 2 + u64(bit)
	}
	return i64(value)
}
