package is_square_free

// Return whether positive n has no repeated prime factor.
@(export)
is_square_free :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > 1_000_000 do return -1
	remaining := n
	for factor := i64(2); factor <= remaining / factor; factor += 1 {
		if remaining % factor == 0 {
			remaining /= factor
			if remaining % factor == 0 do return 0
		}
	}
	return 1
}
