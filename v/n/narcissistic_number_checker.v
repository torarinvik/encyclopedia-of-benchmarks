module narcissistic_number_checker

// Check whether n equals the sum of each decimal digit raised to digit count.
@[export: 'narcissistic_number_checker']
pub fn narcissistic_number_checker(n i64) i64 {
	if n < -2_147_483_648 || n > 999_999 { return -1 }

	original := n
	mut remaining := n
	mut digits := i64(0)
	for remaining != 0 {
		digits++
		remaining /= 10
	}

	mut sum := i64(0)
	remaining = n
	for remaining > 0 {
		digit := remaining % 10
		mut power := i64(1)
		for mut exponent := i64(0); exponent < digits; exponent++ {
			power *= digit
		}
		sum += power
		remaining /= 10
	}
	return if sum == original { i64(1) } else { i64(0) }
}
