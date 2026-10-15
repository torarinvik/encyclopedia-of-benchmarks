fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut factor := i64(2)
	for factor <= value / factor {
		if value % factor == 0 { return false }
		factor++
	}
	return true
}

@[export: 'number_of_primes_by_number_of_digits_sequence']
pub fn number_of_primes_by_number_of_digits_sequence(index i64) i64 {
	if index < 0 || index > 3 { return -1 }
	if index == 0 { return 0 }
	mut lower := i64(1)
	for i := i64(1); i < index; i++ { lower *= 10 }
	upper := lower * 10
	mut count := i64(0)
	for value := lower + 1; value <= upper; value++ {
		if is_prime(value) { count++ }
	}
	return count
}
