module euclid_mullin_sequence

const max_parseable_length = 2
const max_n = i64(8)

fn least_prime_factor(value i64) i64 {
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return divisor }
		divisor++
	}
	return value
}

fn euclid_mullin_term(index i64) i64 {
	mut product := i64(1)
	mut term := i64(1)
	for _ in 0 .. int(index) {
		term = least_prime_factor(product + 1)
		product *= term
	}
	return term
}

@[export: 'euclid_mullin_sequence']
pub fn euclid_mullin_sequence(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 1 || input[0] > max_n { return -1 }
		return euclid_mullin_term(input[0])
	}
}
