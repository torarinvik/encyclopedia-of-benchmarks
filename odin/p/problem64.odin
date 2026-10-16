package problem64

Max_Limit :: 10_000

integer_sqrt :: proc "contextless" (value: i64) -> i64 {
	low := i64(0)
	high := value + 1
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle <= value / middle do low = middle
		else do high = middle
	}
	return low
}

period_length :: proc "contextless" (value, root: i64) -> i64 {
	numerator := i64(0)
	denominator := i64(1)
	coefficient := root
	period := i64(0)
	for {
		numerator = denominator * coefficient - numerator
		denominator = (value - numerator * numerator) / denominator
		coefficient = (root + numerator) / denominator
		period += 1
		if coefficient == 2 * root do break
	}
	return period
}

@(export)
problem64 :: proc "c" (inclusive_limit: i64) -> i64 {
	if inclusive_limit < 0 || inclusive_limit > Max_Limit do return -1
	count := i64(0)
	for value := i64(2); value <= inclusive_limit; value += 1 {
		root := integer_sqrt(value)
		if root * root != value && period_length(value, root) % 2 == 1 do count += 1
	}
	return count
}
