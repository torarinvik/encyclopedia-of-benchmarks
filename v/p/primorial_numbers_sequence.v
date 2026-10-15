fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut factor := i64(2)
	for factor <= value / factor {
		if value % factor == 0 { return false }
		factor++
	}
	return true
}

@[export: 'primorial_numbers_sequence']
pub fn primorial_numbers_sequence(index i64) i64 {
	if index < 0 || index > 15 { return -1 }
	mut product := i64(1)
	mut prime_count := i64(0)
	mut candidate := i64(2)
	for prime_count < index {
		if is_prime(candidate) {
			product *= candidate
			prime_count++
		}
		candidate++
	}
	return product
}
