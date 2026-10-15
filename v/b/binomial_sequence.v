module binomial_sequence

const max_index = i64(230)

fn binomial_coefficient(n i64, k i64) i64 {
	if k == 0 || k == n { return 1 }
	if n < 0 { return 0 }
	return binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1)
}

@[export: 'binomial_sequence']
pub fn binomial_sequence(index i64) i64 {
	if index < 0 || index > max_index { return -1 }
	mut row := i64(0)
	mut row_start := i64(0)
	for index >= row_start + row + 1 {
		row_start += row + 1
		row++
	}
	return binomial_coefficient(row, index - row_start)
}
