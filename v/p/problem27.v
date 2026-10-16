module problem27

fn problem27_is_prime(value i64) bool {
	if value < 2 { return false }
	if value % 2 == 0 { return value == 2 }
	if value % 3 == 0 { return value == 3 }
	mut factor := i64(5)
	for factor <= value / factor {
		if value % factor == 0 || value % (factor + 2) == 0 { return false }
	factor += 6
	}
	return true
}

@[export: 'problem27']
pub fn problem27(limit i64) i64 {
	if limit < 1 || limit > 1000 { return -1 }
	mut best_length := i64(0)
	mut best_a := i64(0)
	mut best_b := i64(0)
	mut a := 1 - limit
	for a < limit {
		mut b := i64(2)
		for b < limit {
			if problem27_is_prime(b) {
				mut n := i64(0)
				for problem27_is_prime(n * n + a * n + b) {
					n++
				}
				if n > best_length {
					best_length = n
					best_a = a
					best_b = b
				}
			}
			b++
		}
		a++
	}
	return best_a * best_b
}
