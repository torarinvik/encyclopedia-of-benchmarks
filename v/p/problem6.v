module problem6

@[export: 'problem6']
pub fn problem6(limit i64) i64 {
	if limit < 0 || limit > 100 { return -1 }
	mut total := i64(0)
	mut sum_of_squares := i64(0)
	for value := i64(1); value <= limit; value++ {
		total += value
		sum_of_squares += value * value
	}
	return total * total - sum_of_squares
}
