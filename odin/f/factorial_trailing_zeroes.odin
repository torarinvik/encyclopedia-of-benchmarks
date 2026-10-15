package factorial_trailing_zeroes

MAX_N :: 1_000_000_000

// Count factors of five in n!, which determine its trailing decimal zeros.
@(export)
factorial_trailing_zeroes :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_N do return -1

	remaining := n
	count := i64(0)
	for remaining > 0 {
		remaining /= 5
		count += remaining
	}
	return count
}
