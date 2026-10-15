module number_of_positive_divisors

// Count positive divisors of the absolute value of one signed integer.
@[export: 'number_of_positive_divisors']
pub fn number_of_positive_divisors(values &i64, length usize) i64 {
	if length != 1 || values[0] < -1000000000 || values[0] > 1000000000 { return -1 }
	mut remaining := values[0]
	if remaining < 0 { remaining = -remaining }
	mut count := i64(1)
	mut factor := i64(2)
	for factor * factor <= remaining {
		mut exponent := i64(0)
		for remaining % factor == 0 {
			remaining /= factor
			exponent++
		}
		count *= exponent + 1
		factor++
	}
	if remaining > 1 { count *= 2 }
	return count
}
