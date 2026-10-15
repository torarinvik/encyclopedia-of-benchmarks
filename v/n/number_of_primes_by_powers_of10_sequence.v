fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut factor := i64(2)
	for factor <= value / factor {
		if value % factor == 0 { return false }
		factor++
	}
	return true
}

@[export: 'number_of_primes_by_powers_of10_sequence']
pub fn number_of_primes_by_powers_of10_sequence(index i64) i64 {
	if index < 0 || index > 3 { return -1 }
	if index == 0 { return 0 }
	mut upper := i64(10)
	for _ in 1 .. index { upper *= 10 }
	mut count := i64(0)
	for value := i64(2); value < upper; value++ {
		if is_prime(value) { count++ }
	}
	return count
}
