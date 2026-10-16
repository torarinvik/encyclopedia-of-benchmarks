module problem120

const max_limit = 1000

@[export: 'problem120']
pub fn problem120(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	mut total := i64(0)
	mut a := i64(3)
	for a <= limit {
		total += 2 * a * ((a - 1) / 2)
		a++
	}
	return total
}
