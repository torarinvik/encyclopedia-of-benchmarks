package perfect_square_checker

// Check whether a signed 32-bit integer is a perfect square.
@(export)
perfect_square_checker :: proc "c" (n: i64) -> i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 do return -1
	if n < 0 do return 0

	low := i64(0)
	high := i64(46_340)
	for low <= high {
		mid := low + (high - low) / 2
		square := mid * mid
		if square == n do return 1
		if square < n do low = mid + 1 else high = mid - 1
	}
	return 0
}
