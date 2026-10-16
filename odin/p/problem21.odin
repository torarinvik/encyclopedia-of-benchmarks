package problem21

proper_divisor_sum :: proc "contextless" (value: i64) -> i64 {
	if value <= 1 do return 0
	total := i64(1)
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor != 0 do continue
		partner := value / divisor
		total += divisor
		if partner != divisor do total += partner
	}
	return total
}

@(export)
problem21 :: proc "c" (limit: i64) -> i64 {
	if limit < 1 || limit > 10000 do return -1
	total := i64(0)
	for value := i64(1); value < limit; value += 1 {
		partner := proper_divisor_sum(value)
		if partner != value && proper_divisor_sum(partner) == value do total += value
	}
	return total
}
