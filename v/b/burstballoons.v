module main

const max_balloons = 128

@[export: 'burstballoons']
pub fn burstballoons(values &i64, length usize) i64 {
	unsafe {
		if length > max_balloons {
			return -1
		}
		for index in 0 .. int(length) {
			if values[index] < 0 || values[index] > 1000 {
				return -1
			}
		}
		if length == 0 {
			return 0
		}

		mut padded := [max_balloons + 2]i64{}
		mut dp := [max_balloons + 2][max_balloons + 2]i64{}
		padded[0] = 1
		padded[int(length) + 1] = 1
		for index in 0 .. int(length) {
			padded[index + 1] = values[index]
		}
		for span in 1 .. int(length) + 1 {
			for left in 1 .. int(length) - span + 2 {
				right := left + span - 1
				mut best := i64(0)
				for last in left .. right + 1 {
					coins := dp[left][last - 1] + dp[last + 1][right]
						+ padded[left - 1] * padded[last] * padded[right + 1]
					if coins > best {
						best = coins
					}
				}
				dp[left][right] = best
			}
		}
		return dp[1][int(length)]
	}
}
