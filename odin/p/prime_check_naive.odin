package prime_check_naive

@(export)
prime_check_naive :: proc "c" (n: i64) -> i64 {
	if n > 10000 do return -1
	if n < 2 do return 0
	for divisor := i64(2); divisor < n; divisor += 1 {
		if n % divisor == 0 do return 0
	}
	return 1
}
