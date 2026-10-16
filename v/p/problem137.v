module problem137

@[export: 'problem137']
pub fn problem137(n i64) i64 {
	if n < 1 || n > 23 { return -1 }
	mut previous := i64(1)
	mut current := i64(1)
	for _ in 0 .. int(2 * n - 1) {
		next := previous + current
		previous = current
		current = next
	}
	return previous * current
}
