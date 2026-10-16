package problem1

@(export)
problem1 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 100_000 do return -1
	total := i64(0)
	for value := i64(1); value < limit; value += 1 {
		if value % 3 == 0 || value % 5 == 0 do total += value
	}
	return total
}
