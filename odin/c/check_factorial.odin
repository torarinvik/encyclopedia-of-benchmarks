package check_factorial

@(export)
check_factorial :: proc "c" (n: i64) -> i64 {
	if n <= 0 do return 0
	value := n
	divisor := i64(2)
	for value % divisor == 0 {
		value /= divisor
		divisor += 1
	}
	if value == 1 do return 1
	return 0
}
