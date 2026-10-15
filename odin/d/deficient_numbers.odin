package deficient_numbers

// Proper-divisor pair scan from the pinned Python source.
@(export)
deficient_numbers :: proc "c" (number: i64) -> i64 {
	if number <= 0 do return 0
	if number > 100_000_000 do return -1
	if number == 1 do return 1

	total: i64 = 1
	for divisor := i64(2); divisor <= number / divisor; divisor += 1 {
		if number % divisor == 0 {
			other := number / divisor
			total += divisor
			if other != divisor do total += other
		}
	}
	if total < number do return 1
	return 0
}
