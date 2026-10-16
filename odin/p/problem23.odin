package problem23

MAX_LIMIT :: 28123

@(export)
problem23 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > MAX_LIMIT { return -1 }
	bound := int(limit)
	proper_divisor_sums: [MAX_LIMIT + 1]i64 = {}
	abundant: [MAX_LIMIT + 1]bool = {}
	representable: [MAX_LIMIT + 1]bool = {}

	for divisor := 1; divisor <= bound / 2; divisor += 1 {
		for multiple := 2 * divisor; multiple <= bound; multiple += divisor {
			proper_divisor_sums[multiple] += i64(divisor)
		}
	}
	for value := 12; value <= bound; value += 1 {
		abundant[value] = proper_divisor_sums[value] > i64(value)
	}
	for left := 12; left <= bound; left += 1 {
		if !abundant[left] { continue }
		for right := left; right <= bound - left; right += 1 {
			if abundant[right] { representable[left + right] = true }
		}
	}

	total: i64 = 0
	for value := 1; value <= bound; value += 1 {
		if !representable[value] { total += i64(value) }
	}
	return total
}
