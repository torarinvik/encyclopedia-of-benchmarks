module trailing_zeroes

// Count decimal zero digits at the end of a nonnegative integer.
@[export: 'trailing_zeroes']
pub fn trailing_zeroes(n i64) i64 {
	if n < 0 { return -1 }
	if n == 0 { return 1 }
	mut remaining := n
	mut count := i64(0)
	for remaining % 10 == 0 {
		count++
		remaining /= 10
	}
	return count
}
