package perfect_number

// Check whether n equals the sum of its positive proper divisors.
@(export)
perfect_number :: proc "c" (n: i64) -> i64 {
	if n <= 1 do return 0
	if n > 1_000_000_000_000 do return -1

	divisor_sum := i64(1)
	for factor := i64(2); factor <= n / factor; factor += 1 {
		if n % factor == 0 {
			divisor_sum += factor
			partner := n / factor
			if partner != factor do divisor_sum += partner
			if divisor_sum > n do return 0
		}
	}
	if divisor_sum == n do return 1
	return 0
}
