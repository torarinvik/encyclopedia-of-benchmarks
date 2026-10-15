package twin_prime

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value == 2 do return true
	if value % 2 == 0 do return false
	divisor: i64 = 3
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

@(export)
twin_prime :: proc "c" (value: i64) -> i64 {
	if value < -4096 || value > 4096 do return -1
	if is_prime(value) && is_prime(value + 2) do return value + 2
	return -1
}
