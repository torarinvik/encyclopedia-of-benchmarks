module sociable_number

fn sum_proper_divisors(number u64) u64 {
	if number <= 1 {
		return 0
	}
	mut total := u64(1)
	mut divisor := u64(2)
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
	return total
}

// Exact-cycle sociable-number check adapted from the pinned Java source.
@[export: 'sociable_number']
pub fn sociable_number(number u64, cycle_length u64) i64 {
	if number == 0 || number > 100000 || cycle_length < 2 || cycle_length > 3 {
		return -1
	}
	mut current := number
	mut step := u64(0)
	for step < cycle_length {
		current = sum_proper_divisors(current)
		if current == number {
			if step == cycle_length - 1 {
				return 1
			}
			return 0
		}
		step++
	}
	return 0
}
