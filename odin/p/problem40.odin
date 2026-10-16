package problem40

digit_at_position :: proc(position_input: i64) -> i64 {
	position := position_input
	digits: i64 = 1
	block_count: i64 = 9
	first_number: i64 = 1
	for position > digits * block_count {
		position -= digits * block_count
		digits += 1
		block_count *= 10
		first_number *= 10
	}
	number := first_number + (position - 1) / digits
	offset := (position - 1) % digits
	divisor: i64 = 1
	power: i64 = 0
	for power < digits - offset - 1 {
		divisor *= 10
		power += 1
	}
	return (number / divisor) % 10
}

@(export)
problem40 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	product := digit_at_position(1)
	product *= digit_at_position(10)
	product *= digit_at_position(100)
	product *= digit_at_position(1_000)
	product *= digit_at_position(10_000)
	product *= digit_at_position(100_000)
	product *= digit_at_position(1_000_000)
	return product
}
