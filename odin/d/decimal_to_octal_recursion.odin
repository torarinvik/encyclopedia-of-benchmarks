package decimal_to_octal_recursion

encode_octal_digits :: proc "contextless" (value: i64) -> i64 {
	if value == 0 do return 0
	return encode_octal_digits(value / 8) * 10 + value % 8
}

// Recursively encode octal digits as a decimal integer.
@(export)
decimal_to_octal_recursion :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 295600127 do return -1
	return encode_octal_digits(value)
}
