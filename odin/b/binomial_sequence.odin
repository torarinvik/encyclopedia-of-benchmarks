package binomial_sequence

MAX_INDEX :: i64(230)

binomial_coefficient :: proc(n, k: i64) -> i64 {
	if k == 0 || k == n do return 1
	if n < 0 do return 0
	return binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1)
}

@(export, link_name="binomial_sequence")
binomial_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > MAX_INDEX do return -1
	row: i64 = 0
	row_start: i64 = 0
	for index >= row_start + row + 1 {
		row_start += row + 1
		row += 1
	}
	return binomial_coefficient(row, index - row_start)
}

main :: proc() {}
