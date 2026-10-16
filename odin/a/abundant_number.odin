package abundant_number

@(export)
abundant_number :: proc "contextless" (n: i64) -> i64 {
	if n < 1 || n > 100_000_000 do return -1
	if n == 1 do return 0
	sum := i64(1)
	for divisor := i64(2); divisor <= n / divisor; divisor += 1 {
		if n % divisor == 0 {
			sum += divisor
			partner := n / divisor
			if partner != divisor do sum += partner
			if sum > n do return 1
		}
	}
	return 0
}
