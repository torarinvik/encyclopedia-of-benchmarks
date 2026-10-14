package binomial_coefficient

// Calculate C(n, k) by updating one row of Pascal's triangle.
@(export)
binomial_coefficient :: proc "c" (n, k: u64) -> i64 {
	if n > 66 do return -1
	if k > n do return 0
	if k == 0 do return 1
	coefficients: [67]i64
	coefficients[0] = 1
	for row: u64 = 1; row <= n; row += 1 {
		column := min(row, k)
		for column > 0 {
			coefficients[column] += coefficients[column - 1]
			column -= 1
		}
	}
	return coefficients[k]
}
