module factorial_trailing_zeroes

// Count factors of five in n!, which determine its trailing decimal zeros.
@[export: 'factorial_trailing_zeroes']
pub fn factorial_trailing_zeroes(n i64) i64 {
	if n < 0 || n > 1_000_000_000 { return -1 }
	mut remaining := n
	mut count := i64(0)
	for remaining > 0 {
		remaining /= 5
		count += remaining
	}
	return count
}
