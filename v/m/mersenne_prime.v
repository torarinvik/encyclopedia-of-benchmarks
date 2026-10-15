fn is_prime_i64(n i64) bool {
	if n < 2 { return false }
	if n % 2 == 0 { return n == 2 }
	mut factor := i64(3)
	for factor <= n / factor {
		if n % factor == 0 { return false }
		factor += 2
	}
	return true
}

@[export: 'mersenne_prime']
pub fn mersenne_prime(n i64) i64 {
	if n == 0 { return 0 }
	if n < 0 || n > 2147483647 { return -1 }
	mut remaining := n + 1
	for remaining % 2 == 0 {
		remaining /= 2
	}
	if remaining != 1 { return 0 }
	return if is_prime_i64(n) { 1 } else { 0 }
}
