package problem6

@(export)
problem6 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 100 do return -1
	total := i64(0)
	sum_of_squares := i64(0)
	for value := i64(1); value <= limit; value += 1 {
		total += value
		sum_of_squares += value * value
	}
	return total * total - sum_of_squares
}
