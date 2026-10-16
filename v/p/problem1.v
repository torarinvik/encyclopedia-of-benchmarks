module problem1

@[export: 'problem1']
pub fn problem1(limit i64) i64 {
	if limit < 0 || limit > 100_000 { return -1 }
	mut total := i64(0)
	mut value := i64(1)
	for value < limit {
		if value % 3 == 0 || value % 5 == 0 { total += value }
		value++
	}
	return total
}
