package reverse_integer

INVALID_RESULT :: i64(-2147483649)

// Reverse a signed 32-bit decimal integer, returning zero on overflow.
@(export)
reverse_integer :: proc "c" (input_value: i64) -> i64 {
	if input_value < -2147483648 || input_value > 2147483647 do return INVALID_RESULT
	input := input_value
	reversed := i64(0)
	for input != 0 {
		digit := input % 10
		input /= 10
		if reversed > 214748364 || (reversed == 214748364 && digit > 7) do return 0
		if reversed < -214748364 || (reversed == -214748364 && digit < -8) do return 0
		reversed = reversed * 10 + digit
	}
	return reversed
}
