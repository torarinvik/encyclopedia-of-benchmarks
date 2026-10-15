package reverse_number

MAX_INPUT :: i64(1_000_000_000)

@(export)
reverse_number :: proc "c" (number: i64) -> i64 {
	if number < 0 || number > MAX_INPUT do return -1
	current := number
	reversed := i64(0)
	for current > 0 {
		reversed = reversed * 10 + current % 10
		current /= 10
	}
	return reversed
}
