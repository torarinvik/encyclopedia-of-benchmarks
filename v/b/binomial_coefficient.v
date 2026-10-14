module binomial_coefficient

// Calculate C(n, k) by updating one row of Pascal's triangle.
@[export: 'binomial_coefficient']
pub fn binomial_coefficient(n u64, k u64) i64 {
	if n > 66 { return -1 }
	if k > n { return 0 }
	if k == 0 { return 1 }
	mut coefficients := [67]i64{init: 0}
	coefficients[0] = 1
	mut row := u64(1)
	for row <= n {
		mut column := if row < k { row } else { k }
		for column > 0 {
			coefficients[int(column)] += coefficients[int(column - 1)]
			column--
		}
		row++
	}
	return coefficients[int(k)]
}
