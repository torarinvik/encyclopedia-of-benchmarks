package derangement

// Return the source-compatible derangement count for n in 0..=20.
@(export)
derangement :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 20 do return -1
	if n < 2 do return 0
	if n == 2 do return 1

	previous: i64 = 1
	previous_previous: i64 = 0
	i: i64 = 3
	for i <= n {
		current := (i - 1) * (previous + previous_previous)
		previous_previous = previous
		previous = current
		i += 1
	}
	return previous
}
