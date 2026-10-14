module armstrong_number

// Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
@[export: 'armstrong_number']
pub fn armstrong_number(n i64) i64 {
	if n < 0 { return 0 }
	if n == 0 { return 1 }
	mut digits := i64(0)
	mut remaining := n
	for remaining > 0 {
		digits++
		remaining /= 10
	}
	mut total := i64(0)
	remaining = n
	for remaining > 0 {
		digit := remaining % 10
		mut power := i64(1)
		mut exponent := i64(0)
		for exponent < digits {
			power *= digit
			exponent++
		}
		if power > n - total { return 0 }
		total += power
		remaining /= 10
	}
	return if total == n { i64(1) } else { i64(0) }
}
