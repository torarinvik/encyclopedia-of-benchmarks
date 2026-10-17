@[export: 'so1']
fn so1(threshold i64) i64 {
	if threshold < -2_147_483_648 || threshold > 1_000_000_000 { return -1 }

	mut first := i64(1)
	mut second := i64(2)
	mut total := i64(0)
	for second <= threshold {
		if second % 2 == 0 { total += second }
		temporary := first
		first = second
		second = temporary + first
	}
	return total
}
