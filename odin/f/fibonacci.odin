package fibonacci

// Iterative Fibonacci for the shared signed 64-bit benchmark contract.
@(export)
fibonacci :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 92 do return -1
	if n == 0 do return 0

	previous := i64(0)
	current := i64(1)
	for index := i64(1); index < n; index += 1 {
		next := previous + current
		previous = current
		current = next
	}
	return current
}
