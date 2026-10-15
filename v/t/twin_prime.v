module twin_prime

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

// Return n + 2 when n and n + 2 are twin primes, otherwise -1.
@[export: 'twin_prime']
pub fn twin_prime(value i64) i64 {
	if value < -4096 || value > 4096 { return -1 }
	if is_prime(value) && is_prime(value + 2) { return value + 2 }
	return -1
}
