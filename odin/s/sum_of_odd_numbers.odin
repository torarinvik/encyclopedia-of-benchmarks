package sum_of_odd_numbers

@(export)
sum_of_odd_numbers :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 46340 do return -1
	return n * n
}
