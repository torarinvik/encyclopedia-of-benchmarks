package problem2

@(export)
problem2 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 4_000_000 do return -1
	previous := i64(1)
	current := i64(2)
	total := i64(0)
	for current < limit {
		if current % 2 == 0 do total += current
		next := previous + current
		previous = current
		current = next
	}
	return total
}
