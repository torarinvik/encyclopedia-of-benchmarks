module binary_to_gray_code

// Convert a nonnegative integer to its binary-reflected Gray code.
@[export: 'binary_to_gray_code']
pub fn binary_to_gray_code(value i64) i64 {
	if value < 0 { return -1 }
	return value ^ (value >> 1)
}
