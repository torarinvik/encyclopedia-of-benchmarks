module derangement

// Return the source-compatible derangement count for n in 0..=20.
@[export: 'derangement']
pub fn derangement(n i64) i64 {
	if n < 0 || n > 20 {
		return -1
	}
	if n < 2 {
		return 0
	}
	if n == 2 {
		return 1
	}

	mut previous := i64(1)
	mut previous_previous := i64(0)
	mut i := i64(3)
	for i <= n {
		current := (i - 1) * (previous + previous_previous)
		previous_previous = previous
		previous = current
		i++
	}
	return previous
}
