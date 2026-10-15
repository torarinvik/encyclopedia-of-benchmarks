package disarium_number

@(export)
disarium_number :: proc "c" (number: i64) -> i64 {
	if number < 1 || number > 99_999_999 do return -1
	digits := i64(0)
	for remaining := number; remaining > 0; remaining /= 10 { digits += 1 }
	position := digits
	remaining := number
	sum := i64(0)
	for remaining > 0 {
		digit := remaining % 10
		power := i64(1)
		for exponent := i64(0); exponent < position; exponent += 1 { power *= digit }
		sum += power
		position -= 1
		remaining /= 10
	}
	if sum == number do return 1
	return 0
}
