package kaprekar_number

@(export)
kaprekar_number :: proc "c" (number: i64) -> i64 {
	if number < 1 do return 0
	if number > 2_000_000_000 do return -1
	if number == 1 do return 1
	square := number * number
	split := i64(10)
	for split <= square {
		right := square % split
		if right > 0 && square / split + right == number do return 1
		if split > square / 10 do break
		split *= 10
	}
	return 0
}
