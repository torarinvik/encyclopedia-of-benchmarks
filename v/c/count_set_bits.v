module count_set_bits

const max_input = i64(67108863)

fn highest_power_position(value i64) int {
	mut position := 0
	mut power := i64(1)
	for power <= value / 2 {
		power *= 2
		position++
	}
	return position
}

fn count_set_bits_recursive(value i64) i64 {
	if value == 0 { return 0 }
	position := highest_power_position(value)
	power := i64(1) << position
	mut bits_at_position := i64(0)
	if position > 0 { bits_at_position = i64(position) * (power >> 1) }
	remaining_numbers := value - power + 1
	return bits_at_position + remaining_numbers + count_set_bits_recursive(value - power)
}

// Count set bits across every integer from 1 through value, inclusive.
@[export: 'count_set_bits']
pub fn count_set_bits(value i64) i64 {
	if value < 0 || value > max_input { return -1 }
	return count_set_bits_recursive(value)
}
