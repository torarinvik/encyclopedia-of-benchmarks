package problem26

@(export)
problem26 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 1000 do return -1
	best_denominator := i64(1)
	longest_remainder_list := i64(0)
	for denominator := i64(1); denominator <= limit; denominator += 1 {
		seen: [1001]bool = {}
		remainder := i64(1)
		remainder_count := i64(0)
		for step := i64(0); step < limit; step += 1 {
			if seen[remainder] {
				if remainder_count > longest_remainder_list {
					longest_remainder_list = remainder_count
					best_denominator = denominator
				}
				break
			}
			seen[remainder] = true
			remainder_count += 1
			remainder = (remainder * 10) % denominator
		}
	}
	return best_denominator
}
