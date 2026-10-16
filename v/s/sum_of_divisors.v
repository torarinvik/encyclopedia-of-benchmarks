module sum_of_divisors

// Return the sum of all positive divisors of n by prime factorization.
@[export: 'sum_of_divisors']
pub fn sum_of_divisors(n i64) i64 {
	if n < 1 || n > 1000000 { return -1 }
	mut remaining := n
	mut sigma := i64(1)
	mut factor := i64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			mut power := i64(1)
			mut geometric_sum := i64(1)
			for remaining % factor == 0 {
				remaining /= factor
				power *= factor
				geometric_sum += power
			}
			sigma *= geometric_sum
		}
		factor++
	}
	if remaining > 1 { sigma *= remaining + 1 }
	return sigma
}
