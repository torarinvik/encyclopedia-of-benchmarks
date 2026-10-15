package minimum_cost_path

INVALID_RESULT :: i64(-9223372036854775807 - 1)

@(export)
minimum_cost_path :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 do return INVALID_RESULT
	rv, cv := values[0], values[1]
	if rv < 1 || rv > 16 || cv < 1 || cv > 16 do return INVALID_RESULT
	rows, cols := int(rv), int(cv)
	if length != c.size_t(2 + rows * cols) do return INVALID_RESULT
	 dp: [16][16]i64
	for r := 0; r < rows; r += 1 {
		for col := 0; col < cols; col += 1 {
			x := values[2 + r * cols + col]
			if x < -2147483648 || x > 2147483647 do return INVALID_RESULT
			dp[r][col] = x
		}
	}
	for col := 1; col < cols; col += 1 do dp[0][col] += dp[0][col - 1]
	for r := 1; r < rows; r += 1 do dp[r][0] += dp[r - 1][0]
	for r := 1; r < rows; r += 1 {
		for col := 1; col < cols; col += 1 {
			prev := min(dp[r - 1][col], dp[r][col - 1])
			dp[r][col] += prev
		}
	}
	return dp[rows - 1][cols - 1]
}
