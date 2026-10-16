module problem40

fn digit_at_position(position_input i64) i64 {
	mut position := position_input
	mut digits := i64(1)
	mut block_count := i64(9)
	mut first_number := i64(1)
	for position > digits * block_count {
		position -= digits * block_count
		digits++
		block_count *= 10
		first_number *= 10
	}
	number := first_number + (position - 1) / digits
	offset := (position - 1) % digits
	mut divisor := i64(1)
	mut power := i64(0)
	for power < digits - offset - 1 {
		divisor *= 10
		power++
	}
	return (number / divisor) % 10
}

@[export: 'problem40']
pub fn problem40(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut product := digit_at_position(1)
	product *= digit_at_position(10)
	product *= digit_at_position(100)
	product *= digit_at_position(1_000)
	product *= digit_at_position(10_000)
	product *= digit_at_position(100_000)
	product *= digit_at_position(1_000_000)
	return product
}
