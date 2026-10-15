module binary_count_trailing_zeros

// Count low-order zero bits by shifting away factors of two.
@[export: 'binary_count_trailing_zeros']
pub fn binary_count_trailing_zeros(n i64) i64 {
	if n < 0 { return -1 }
	mut remaining := n
	mut count := i64(0)
	for remaining > 0 && (remaining & 1) == 0 {
		remaining >>= 1
		count++
	}
	return count
}
