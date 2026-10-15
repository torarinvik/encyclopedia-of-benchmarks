module perfect_square_checker

// Check whether a signed 32-bit integer is a perfect square.
@[export: 'perfect_square_checker']
pub fn perfect_square_checker(n i64) i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 { return -1 }
	if n < 0 { return 0 }

	mut low := i64(0)
	mut high := i64(46_340)
	for low <= high {
		mid := low + (high - low) / 2
		square := mid * mid
		if square == n { return 1 }
		if square < n { low = mid + 1 } else { high = mid - 1 }
	}
	return 0
}
