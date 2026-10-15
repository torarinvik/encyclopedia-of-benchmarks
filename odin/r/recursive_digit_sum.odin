package recursive_digit_sum

digit_sum :: proc(number: i64) -> i64 {
	remaining := number
	sum: i64 = 0
	for remaining != 0 {
		sum += remaining % 10
		remaining /= 10
	}
	return sum
}

@(export)
recursive_digit_sum :: proc "contextless" (number, repetitions: i64) -> i64 {
	if number < 0 || repetitions < 0 || repetitions > 1_000_000 do return -1
	total := digit_sum(number) * repetitions
	for total >= 10 {
		total = digit_sum(total)
	}
	return total
}
