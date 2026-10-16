module problem26

@[export: 'problem26']
pub fn problem26(limit i64) i64 {
	if limit < 0 || limit > 1000 { return -1 }
	mut best_denominator := i64(1)
	mut longest_remainder_list := i64(0)
	for denominator := i64(1); denominator <= limit; denominator++ {
		mut seen := [1001]bool{}
		mut remainder := i64(1)
		mut remainder_count := i64(0)
		for step := i64(0); step < limit; step++ {
			if unsafe { seen[remainder] } {
				if remainder_count > longest_remainder_list {
					longest_remainder_list = remainder_count
					best_denominator = denominator
				}
				break
			}
			seen[remainder] = true
			remainder_count++
			remainder = (remainder * 10) % denominator
		}
	}
	return best_denominator
}
