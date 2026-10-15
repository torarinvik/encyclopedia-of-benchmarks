package highest_set_bit

// Return the zero-based index of the most significant set bit.
@(export)
highest_set_bit :: proc "c" (value: i64) -> i64 {
	if value <= 0 {
		return -1
	}
	remaining := value
	position: i64 = -1
	for remaining > 0 {
		position += 1
		remaining >>= 1
	}
	return position
}
