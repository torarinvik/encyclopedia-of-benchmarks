package next_prime_number

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value == 2 do return true
	if value % 2 == 0 do return false
	divisor: i64 = 3
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

// Find the smallest prime strictly greater than the input.
@(export)
next_prime_number :: proc "c" (value: i64) -> i64 {
	if value < -4096 || value > 4096 do return -1
	candidate := value + 1
	if candidate < 2 do candidate = 2
	for !is_prime(candidate) { candidate += 1 }
	return candidate
}
