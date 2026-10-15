package trailing_zeroes

// Count decimal zero digits at the end of a nonnegative integer.
@(export)
trailing_zeroes :: proc "c" (n: i64) -> i64 {
	if n < 0 do return -1
	if n == 0 do return 1

	remaining := n
	count := i64(0)
	for remaining % 10 == 0 {
		count += 1
		remaining /= 10
	}
	return count
}
