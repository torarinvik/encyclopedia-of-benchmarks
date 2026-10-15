package circular_right_shift

// Rotate an unsigned 53-bit integer right by 0 through 53 positions.
@(export)
circular_right_shift :: proc "c" (value, shift: u64) -> i64 {
	mask := u64(9007199254740991)
	if value > mask || shift > 53 do return -1
	low_mask := mask >> (53 - shift)
	low := (value & low_mask) << (53 - shift)
	high := value >> shift
	return i64(low | high)
}
