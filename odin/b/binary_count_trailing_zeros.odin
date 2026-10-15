package binary_count_trailing_zeros

// Count low-order zero bits by shifting away factors of two.
@(export)
binary_count_trailing_zeros :: proc "c" (n: i64) -> i64 {
	if n < 0 do return -1

	remaining := n
	count := i64(0)
	for remaining > 0 && (remaining & 1) == 0 {
		remaining >>= 1
		count += 1
	}
	return count
}
