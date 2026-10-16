package problem36

const MAX_LIMIT :: 1_000_000

is_decimal_palindrome :: proc "contextless" (value: i64) -> bool {
	remaining := value
	reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

is_binary_palindrome :: proc "contextless" (value: i64) -> bool {
	remaining := value
	reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 2 + remaining % 2
		remaining /= 2
	}
	return reversed == value
}

@(export)
problem36 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > MAX_LIMIT do return -1
	total := i64(0)
	for value := i64(1); value < limit; value += 1 {
		if is_decimal_palindrome(value) && is_binary_palindrome(value) do total += value
	}
	return total
}
