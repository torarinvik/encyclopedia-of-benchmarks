module main

const max_n = i64(10)
const search_max = i64(64)
const max_parseable_length = usize(2)

fn is_prime_trial(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn fortunate_term(n i64) i64 {
	mut primorial := i64(1)
	mut primes_found := i64(0)
	mut candidate := i64(2)
	for primes_found < n {
		if is_prime_trial(candidate) {
			primorial *= candidate
			primes_found++
		}
		candidate++
	}
	mut offset := i64(2)
	for offset <= search_max {
		if is_prime_trial(primorial + offset) { return offset }
		offset++
	}
	return -2
}

@[export: 'fortunate_numbers']
pub fn fortunate_numbers(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 { return -1 }
		n := input[0]
		if n < 1 || n > max_n { return -1 }
		return fortunate_term(n)
	}
}
