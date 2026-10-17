package so1

@(export)
so1 :: proc "contextless" (threshold: i64) -> i64 {
	if threshold < -2_147_483_648 || threshold > 1_000_000_000 do return -1

	first := i64(1)
	second := i64(2)
	total := i64(0)
	for second <= threshold {
		if second % 2 == 0 do total += second
		temporary := first
		first = second
		second = temporary + first
	}
	return total
}
