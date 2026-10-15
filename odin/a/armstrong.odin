package armstrong

// Check whether n is an Armstrong number in base 10.
@(export)
armstrong :: proc "c" (n: i64) -> i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 do return -1
	if n < 0 do return 0
	if n == 0 do return 1

	original := n
	remaining := n
	digits := i64(0)
	for remaining > 0 {
		digits += 1
		remaining /= 10
	}

	sum := i64(0)
	remaining = n
	for remaining > 0 {
		digit := remaining % 10
		power := i64(1)
		for exponent := i64(0); exponent < digits; exponent += 1 {
			power *= digit
		}
		sum += power
		remaining /= 10
	}
	if sum == original do return 1
	return 0
}
