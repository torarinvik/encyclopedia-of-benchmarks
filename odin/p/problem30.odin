package problem30

digit_fifth_power :: proc(digit: i64) -> i64 {
	return digit * digit * digit * digit * digit
}

@(export)
problem30 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	total: i64 = 0
	for number := i64(1_000); number < 1_000_000; number += 1 {
		remaining := number
		digit_sum: i64 = 0
		for remaining > 0 {
			digit_sum += digit_fifth_power(remaining % 10)
			remaining /= 10
		}
		if digit_sum == number { total += number }
	}
	return total
}
