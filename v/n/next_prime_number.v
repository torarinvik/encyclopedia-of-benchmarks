module next_prime_number

fn is_candidate_prime(value u32) bool {
	if value % 3 == 0 { return false }
	mut divisor := u32(5)
	for divisor * divisor <= value {
		if value % divisor == 0 || value % (divisor + 2) == 0 { return false }
		divisor += 6
	}
	return true
}

// Find the smallest prime strictly greater than the input.
@[export: 'next_prime_number']
pub fn next_prime_number(value i64) i64 {
	if value < -4096 || value > 4096 { return -1 }
	if value < 2 { return 2 }
	if value == 2 { return 3 }
	mut candidate := u32(value + 1) | 1
	for !is_candidate_prime(candidate) { candidate += 2 }
	return i64(candidate)
}
