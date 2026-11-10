package keith_number

@(export)
keith_number :: proc "c" (number: i64) -> i64 {
	if number < 10 || number > 999999 do return -1
	reversed: [6]i64 = {}
	digits: [6]i64 = {}
	value := number
	digit_count := i64(0)
	for value > 0 {
		reversed[digit_count] = value % 10
		digit_count += 1
		value /= 10
	}
	total := i64(0)
	for i := i64(0); i < digit_count; i += 1 {
		digits[i] = reversed[digit_count - 1 - i]
		total += digits[i]
	}

	oldest := i64(0)
	for {
		next := total
		if next >= number do return i64(next == number)
		total = total - digits[oldest] + next
		digits[oldest] = next
		oldest = (oldest + 1) % digit_count
	}
}
