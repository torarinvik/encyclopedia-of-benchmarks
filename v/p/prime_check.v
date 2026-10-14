module prime_check

// Trial-division primality check over the shared bounded integer domain.
@[export: 'prime_check']
pub fn prime_check(n i64) i64 {
	if n < 2 { return 0 }
	if n > 2147483647 { return -1 }
	if n % 2 == 0 { return if n == 2 { i64(1) } else { i64(0) } }
	mut factor := i64(3)
	for factor <= n / factor {
		if n % factor == 0 { return 0 }
		factor += 2
	}
	return 1
}
