module minimum_cost_path

@[export: 'minimum_cost_path']
pub fn minimum_cost_path(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 3 { return invalid }
	rv, cv := values[0], values[1]
	if rv < 1 || rv > 16 || cv < 1 || cv > 16 { return invalid }
	rows, cols := int(rv), int(cv)
	if length != 2 + rows * cols { return invalid }
	mut dp := [16][16]i64{}
	for r in 0 .. rows {
		for c in 0 .. cols {
			x := values[2 + r * cols + c]
			if x < -2147483648 || x > 2147483647 { return invalid }
			dp[r][c] = x
		}
	}
	for c in 1 .. cols { dp[0][c] += dp[0][c - 1] }
	for r in 1 .. rows { dp[r][0] += dp[r - 1][0] }
	for r in 1 .. rows {
		for c in 1 .. cols {
			dp[r][c] += if dp[r - 1][c] < dp[r][c - 1] { dp[r - 1][c] } else { dp[r][c - 1] }
		}
	}
	return dp[rows - 1][cols - 1]
}
