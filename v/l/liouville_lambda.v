module liouville_lambda

// Liouville's function: (-1) raised to the number of prime factors with multiplicity.
@[export: 'liouville_lambda']
pub fn liouville_lambda(input i64) i64 {
	if input < 1 || input > 2147483647 { return -1 }
	mut remaining := u64(input)
	mut sign := i64(1)
	mut factor := u64(2)
	for factor <= remaining / factor {
		for remaining % factor == 0 {
			remaining /= factor
			sign = -sign
		}
		if factor == 2 { factor = 3 } else { factor += 2 }
	}
	if remaining > 1 { sign = -sign }
	return sign
}
