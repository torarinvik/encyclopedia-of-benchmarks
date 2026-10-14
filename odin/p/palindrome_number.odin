package palindrome_number

// Reverse half the digits to avoid overflow.
@(export)
palindrome_number :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 2_147_483_647 do return -1
	if value != 0 && value % 10 == 0 do return 0
	remaining := value
	reversed_half := i64(0)
	for remaining > reversed_half {
		reversed_half = reversed_half * 10 + remaining % 10
		remaining /= 10
	}
	if remaining == reversed_half || remaining == reversed_half / 10 do return 1
	return 0
}
