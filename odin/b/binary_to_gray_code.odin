package binary_to_gray_code

// Convert a nonnegative integer to its binary-reflected Gray code.
@(export)
binary_to_gray_code :: proc "c" (value: i64) -> i64 {
	if value < 0 do return -1
	return value ^ (value >> 1)
}
