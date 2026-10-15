module armstrong

// Check whether n is an Armstrong number in base 10.
@[export: 'armstrong']
pub fn armstrong(n i64) i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 { return -1 }
	if n < 0 { return 0 }
	if n == 0 { return 1 }

	original := n
	mut remaining := n
	mut digits := i64(0)
	for remaining > 0 {
		digits++
		remaining /= 10
	}

	mut sum := i64(0)
	remaining = n
	for remaining > 0 {
		digit := remaining % 10
		mut power := i64(1)
		mut exponent := i64(0)
		for exponent < digits {
			power *= digit
			exponent++
		}
		sum += power
		remaining /= 10
	}
	return if sum == original { i64(1) } else { i64(0) }
}
