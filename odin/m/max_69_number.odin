package max_69_number

@(export)
max_69_number :: proc "c" (value: i64) -> i64 {
	if value < 1 || value > 999999999999999999 do return -1
	place := i64(1)
	for place <= value / 10 {
		place *= 10
	}
	for place > 0 {
		digit := (value / place) % 10
		if digit == 6 do return value + 3 * place
		if digit != 9 do return -1
		place /= 10
	}
	return -1
}
