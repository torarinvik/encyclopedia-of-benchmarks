module krishnamurthy_number_checker

// Check whether n equals the sum of factorials of its decimal digits.
@[export: 'krishnamurthy_number_checker']
pub fn krishnamurthy_number_checker(n i64) i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 { return -1 }
	if n <= 0 { return 0 }

	original := n
	mut remaining := n
	mut sum := i64(0)
	for remaining != 0 {
		digit := remaining % 10
		mut factorial := i64(1)
		for factor := i64(2); factor <= digit; factor++ {
			factorial *= factor
		}
		sum += factorial
		remaining /= 10
	}
	return if sum == original { i64(1) } else { i64(0) }
}
