module prime_check_naive

@[export: 'prime_check_naive']
pub fn prime_check_naive(n i64) i64 {
	if n > 10000 { return -1 }
	if n < 2 { return 0 }
	mut divisor := i64(2)
	for divisor < n {
		if n % divisor == 0 { return 0 }
		divisor += 1
	}
	return 1
}
