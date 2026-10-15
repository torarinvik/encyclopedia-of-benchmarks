module find_previous_power_of_two

// Repeated-doubling search from the pinned source, bounded to its i32 domain.
@[export: 'find_previous_power_of_two']
pub fn find_previous_power_of_two(number i64) i64 {
	if number < 0 || number > 2147483647 {
		return -1
	}
	if number == 0 {
		return 0
	}

	mut power := i64(1)
	for power <= number {
		power <<= 1
	}
	if number > 1 {
		return power >> 1
	}
	return 1
}
