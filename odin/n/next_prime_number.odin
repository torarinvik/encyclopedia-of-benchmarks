package next_prime_number

is_candidate_prime :: proc "contextless" (value: u32) -> bool {
	if value % 3 == 0 do return false
	for divisor := u32(5); divisor * divisor <= value; divisor += 6 {
		if value % divisor == 0 || value % (divisor + 2) == 0 do return false
	}
	return true
}

// Find the smallest prime strictly greater than the input.
@(export)
next_prime_number :: proc "c" (value: i64) -> i64 {
	if value < -4096 || value > 4096 do return -1
	if value < 2 do return 2
	if value == 2 do return 3
	candidate := u32(value + 1) | 1
	for !is_candidate_prime(candidate) { candidate += 2 }
	return i64(candidate)
}
