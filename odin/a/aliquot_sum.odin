package aliquot_sum

// Scan proper divisors under the shared signed 64-bit contract.
@(export)
aliquot_sum :: proc "c" (n: i64) -> i64 {
	if n < 0 do return -1
	total := i64(0)
	for divisor := i64(1); divisor <= n / 2; divisor += 1 {
		if n % divisor == 0 {
			if total > 9223372036854775807 - divisor do return -1
			total += divisor
		}
	}
	return total
}
