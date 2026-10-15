module highest_set_bit

// Return the zero-based index of the most significant set bit.
@[export: 'highest_set_bit']
pub fn highest_set_bit(value i64) i64 {
	if value <= 0 {
		return -1
	}
	mut remaining := value
	mut position := i64(-1)
	for remaining > 0 {
		position++
		remaining >>= 1
	}
	return position
}
