package gray_to_binary

// Convert a nonnegative reflected Gray-code integer to its binary integer.
@(export)
gray_to_binary :: proc "c" (gray_value: i64) -> i64 {
	if gray_value < 0 do return -1
	binary := gray_value
	remaining := gray_value >> 1
	for remaining != 0 {
		binary ^= remaining
		remaining >>= 1
	}
	return binary
}
