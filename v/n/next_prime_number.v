module next_prime_number

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value == 2 { return true }
	if value % 2 == 0 { return false }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

// Find the smallest prime strictly greater than the input.
@[export: 'next_prime_number']
pub fn next_prime_number(value i64) i64 {
	if value < -4096 || value > 4096 { return -1 }
	mut candidate := value + 1
	if candidate < 2 { candidate = 2 }
	for !is_prime(candidate) { candidate++ }
	return candidate
}
