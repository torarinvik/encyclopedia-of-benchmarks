package factorial

// Iterative factorial for the shared signed 64-bit benchmark contract.
@(export)
factorial :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 20 do return -1

	product := i64(1)
	for factor := i64(2); factor <= n; factor += 1 {
		product *= factor
	}
	return product
}
