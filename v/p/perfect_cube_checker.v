module perfect_cube_checker

// Check whether a signed 32-bit integer is a perfect cube.
@[export: 'perfect_cube_checker']
pub fn perfect_cube_checker(n i64) i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 { return -1 }

	mut magnitude := n
	if magnitude < 0 { magnitude = -magnitude }
	mut low := i64(0)
	mut high := i64(1290)
	for low <= high {
		mid := low + (high - low) / 2
		cube := mid * mid * mid
		if cube == magnitude { return 1 }
		if cube < magnitude { low = mid + 1 } else { high = mid - 1 }
	}
	return 0
}
