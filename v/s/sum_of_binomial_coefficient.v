module sum_of_binomial_coefficient

// Sum of a full binomial row, computed as 2^n.
@[export: 'sum_of_binomial_coefficient']
pub fn sum_of_binomial_coefficient(n i64) i64 {
	if n < 0 || n > 30 {
		return -1
	}
	return i64(1) << int(n)
}
