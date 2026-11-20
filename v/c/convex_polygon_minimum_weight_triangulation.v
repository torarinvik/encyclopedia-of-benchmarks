module convex_polygon_minimum_weight_triangulation

const max_n = 10
const max_length = 37

@[export: 'convex_polygon_minimum_weight_triangulation']
pub fn convex_polygon_minimum_weight_triangulation(input &i64, length usize) i64 {
	if length < 1 || length > max_length { return -1 }
	unsafe {
		if input == nil { return -1 }
		if input[0] < 3 || input[0] > max_n { return -1 }
		n := int(input[0])
		mut diagonal_count := 0
		for i in 0 .. n {
			for j in (i + 2) .. n {
				if !(i == 0 && j == n - 1) { diagonal_count++ }
			}
		}
		if length != usize(1 + diagonal_count) { return -1 }

		mut weight := [max_n][max_n]i64{}
		mut at := 1
		for i in 0 .. n {
			for j in (i + 2) .. n {
				if i == 0 && j == n - 1 { continue }
				value := input[at]
				if value < 0 || value > 1000 { return -1 }
				weight[i][j] = value
				at++
			}
		}

		mut dp := [max_n][max_n]i64{}
		for span in 2 .. n {
			for left in 0 .. (n - span) {
				right := left + span
				mut best := i64(7001)
				for split in (left + 1) .. right {
					left_edge := if split - left == 1 { i64(0) } else { weight[left][split] }
					right_edge := if right - split == 1 { i64(0) } else { weight[split][right] }
					candidate := dp[left][split] + dp[split][right] + left_edge + right_edge
					if candidate < best { best = candidate }
				}
				dp[left][right] = best
			}
		}
		return dp[0][n - 1]
	}
}
