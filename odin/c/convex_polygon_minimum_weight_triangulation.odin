package convex_polygon_minimum_weight_triangulation

import "core:c"

@(export)
convex_polygon_minimum_weight_triangulation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 37 do return -1
	if input[0] < 3 || input[0] > 10 do return -1
	n := int(input[0])
	diagonal_count := 0
	for i in 0..<n {
		for j in (i + 2)..<n {
			if !(i == 0 && j == n - 1) do diagonal_count += 1
		}
	}
	if length != c.size_t(1 + diagonal_count) do return -1

	weight: [10][10]i64
	at := 1
	for i in 0..<n {
		for j in (i + 2)..<n {
			if i == 0 && j == n - 1 do continue
			value := input[at]
			if value < 0 || value > 1000 do return -1
			weight[i][j] = value
			at += 1
		}
	}

	dp: [10][10]i64
	for span in 2..<n {
		for left in 0..<(n - span) {
			right := left + span
			best: i64 = 7001
			for split in (left + 1)..<right {
				left_edge: i64 = 0
				if split - left > 1 do left_edge = weight[left][split]
				right_edge: i64 = 0
				if right - split > 1 do right_edge = weight[split][right]
				candidate := dp[left][split] + dp[split][right] + left_edge + right_edge
				if candidate < best do best = candidate
			}
			dp[left][right] = best
		}
	}
	return dp[0][n - 1]
}
