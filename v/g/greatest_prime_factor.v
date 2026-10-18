module greatest_prime_factor

fn is_prime_trial(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

// Greatest prime factor over the bounded primelib input domain.
@[export: 'greatest_prime_factor']
pub fn greatest_prime_factor(n i64) i64 {
	if n < 0 || n > 1_000_000 { return -1 }
	if n < 2 { return n }
	if is_prime_trial(n) { return n }

	mut quotient := n
	mut largest := i64(0)
	mut factor := i64(2)
	for quotient != 1 {
		if is_prime_trial(factor) && quotient % factor == 0 {
			largest = factor
			quotient /= factor
		} else {
			factor++
		}
	}
	return largest
}
