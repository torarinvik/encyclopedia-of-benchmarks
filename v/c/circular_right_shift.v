module circular_right_shift

// Rotate an unsigned 53-bit integer right by 0 through 53 positions.
@[export: 'circular_right_shift']
pub fn circular_right_shift(value u64, shift u64) i64 {
	mask := u64(9007199254740991)
	if value > mask || shift > 53 { return -1 }
	left_amount := u64(53) - shift
	low_mask := mask >> left_amount
	low := (value & low_mask) << left_amount
	high := value >> shift
	return i64(low | high)
}
