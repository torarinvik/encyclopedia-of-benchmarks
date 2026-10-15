package strong_number

@(export)
strong_number :: proc "c" (number: i64) -> i64 {
	if number < -2_147_483_648 || number > 2_147_483_647 do return -1
	if number < 0 do return 0
	remaining := number
	sum := i64(0)
	if remaining == 0 do sum = 1
	for remaining > 0 {
		digit := remaining % 10
		factorial := i64(1)
		for factor := i64(2); factor <= digit; factor += 1 { factorial *= factor }
		sum += factorial
		remaining /= 10
	}
	if sum == number do return 1
	return 0
}
