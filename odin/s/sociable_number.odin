package sociable_number

sum_proper_divisors :: proc(number: u64) -> u64 {
	if number <= 1 do return 0
	total: u64 = 1
	divisor: u64 = 2
	for divisor <= number / divisor {
		if number % divisor == 0 {
			other := number / divisor
			total += divisor
			if other != divisor do total += other
		}
		divisor += 1
	}
	return total
}

// Exact-cycle sociable-number check adapted from the pinned Java source.
@(export)
sociable_number :: proc "c" (number, cycle_length: u64) -> i64 {
	if number == 0 || number > 100_000 || cycle_length < 2 || cycle_length > 3 do return -1
	current := number
	for step := u64(0); step < cycle_length; step += 1 {
		current = sum_proper_divisors(current)
		if current == number {
			if step == cycle_length - 1 do return 1
			return 0
		}
	}
	return 0
}
