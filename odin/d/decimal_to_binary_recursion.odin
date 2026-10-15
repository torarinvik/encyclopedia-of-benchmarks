package decimal_to_binary_recursion

encode_binary_digits :: proc(value: i64) -> i64 {
	if value == 0 do return 0
	return (value % 2) + 10 * encode_binary_digits(value / 2)
}

// Recursively encode binary digits as a decimal integer, for inputs 0..1023.
@(export)
decimal_to_binary_recursion :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 1023 do return -1
	return encode_binary_digits(value)
}
