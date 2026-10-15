package circular_left_shift

// Rotate an unsigned 53-bit integer left by 0 through 53 positions.
@(export)
circular_left_shift :: proc "c" (value, shift: u64) -> i64 {
	mask := u64(9007199254740991)
	if value > mask || shift > 53 do return -1
	low := (value & (mask >> shift)) << shift
	high := value >> (53 - shift)
	return i64(low | high)
}
