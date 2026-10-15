package index_of_right_most_set_bit

INT32_MIN_VALUE :: i64(-2_147_483_648)
INT32_MAX_VALUE :: i64(2_147_483_647)

// Zero-based trailing set-bit index using the Java magnitude behavior.
@(export)
index_of_right_most_set_bit :: proc "c" (value: i64) -> i64 {
	if value < INT32_MIN_VALUE || value > INT32_MAX_VALUE || value == 0 do return -1
	magnitude := i64(0)
	if value < 0 do magnitude = -value else magnitude = value
	index := i64(0)
	for magnitude % 2 == 0 {
		magnitude /= 2
		index += 1
	}
	return index
}
