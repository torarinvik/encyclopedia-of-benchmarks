package neon_number

@(export)
neon_number :: proc "c" (number: i64) -> i64 {
	if number < 0 do return 0
	if number > 3_000_000_000 do return -1
	square := number * number
	digit_sum := i64(0)
	for square > 0 {
		digit_sum += square % 10
		square /= 10
	}
	if digit_sum == number do return 1
	return 0
}
