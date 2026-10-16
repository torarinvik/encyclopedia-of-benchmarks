package problem10

@(export)
problem10 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 2_000_000 do return -1
	composite: [1_000_000]bool = {}
	odd_count := limit / 2
	total := i64(0)
	if limit > 2 do total = 2
	for prime := i64(3); prime * prime < limit; prime += 2 {
		if !composite[prime / 2] {
			for index := prime * prime / 2; index < odd_count; index += prime {
				composite[index] = true
			}
		}
	}
	for index := i64(1); index < odd_count; index += 1 {
		if !composite[index] do total += 2 * index + 1
	}
	return total
}
