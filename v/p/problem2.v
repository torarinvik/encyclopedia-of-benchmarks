module problem2

@[export: 'problem2']
pub fn problem2(limit i64) i64 {
	if limit < 0 || limit > 4_000_000 { return -1 }
	mut previous := i64(1)
	mut current := i64(2)
	mut total := i64(0)
	for current < limit {
		if current % 2 == 0 { total += current }
		next := previous + current
		previous = current
		current = next
	}
	return total
}
