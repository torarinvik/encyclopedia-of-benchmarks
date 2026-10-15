package jacobsthal_number

// Return J(n) for the bounded signed-64-bit Jacobsthal index.
@(export)
jacobsthal_number :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 64 do return -1
	if n == 0 do return 0
	previous := i64(0)
	current := i64(1)
	for index := i64(2); index <= n; index += 1 {
		next := current + 2 * previous
		previous = current
		current = next
	}
	return current
}
