module abs

// Return the signed 64-bit magnitude, or -1 when it cannot be represented.
@[export: 'abs_i64']
pub fn abs_i64(input i64) i64 {
	if input == -9223372036854775807 - 1 { return -1 }
	if input < 0 { return -input }
	return input
}
