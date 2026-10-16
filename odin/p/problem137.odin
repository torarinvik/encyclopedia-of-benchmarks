package problem137

@(export)
problem137 :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > 23 do return -1
	previous := i64(1)
	current := i64(1)
	for index := i64(0); index < 2 * n - 1; index += 1 {
		next := previous + current
		previous = current
		current = next
	}
	return previous * current
}
