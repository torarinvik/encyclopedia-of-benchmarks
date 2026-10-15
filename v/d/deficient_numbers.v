module deficient_numbers

// Proper-divisor pair scan from the pinned Python source.
@[export: 'deficient_numbers']
pub fn deficient_numbers(number i64) i64 {
	if number <= 0 {
		return 0
	}
	if number > 100000000 {
		return -1
	}
	if number == 1 {
		return 1
	}

	mut total := i64(1)
	mut divisor := i64(2)
	for divisor <= number / divisor {
		if number % divisor == 0 {
			other := number / divisor
			total += divisor
			if other != divisor {
				total += other
			}
		}
		divisor++
	}
	if total < number {
		return 1
	}
	return 0
}
