package problem21_pair_sum

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
problem21_pair_sum :: proc "c" (limit: i64) -> i64 {
	if limit < 2 || limit > 10000 do return -1
	total := i64(0)
	for smaller := i64(2); smaller < limit; smaller += 1 {
		larger := proper_divisor_sum(smaller)
		if larger > smaller && proper_divisor_sum(larger) == smaller do total += smaller + larger
	}
	return total
}
