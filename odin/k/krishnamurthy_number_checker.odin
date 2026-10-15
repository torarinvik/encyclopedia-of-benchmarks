package krishnamurthy_number_checker

// Check whether n equals the sum of factorials of its decimal digits.
@(export)
krishnamurthy_number_checker :: proc "c" (n: i64) -> i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 do return -1
	if n <= 0 do return 0

	original := n
	remaining := n
	sum := i64(0)
	for remaining != 0 {
		digit := remaining % 10
		factorial := i64(1)
		for factor := i64(2); factor <= digit; factor += 1 {
			factorial *= factor
		}
		sum += factorial
		remaining /= 10
	}
	if sum == original do return 1
	return 0
}
