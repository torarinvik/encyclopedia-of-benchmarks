module max_non_adjacent_sum

@[export: 'max_non_adjacent_sum']
pub fn max_non_adjacent_sum(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 1 || length > 100000 { return invalid }
	mut two_back := i64(0)
	mut one_back := i64(0)
	for i in 0 .. int(length) {
		value := values[i]
		if value < 0 || value > 10000 { return invalid }
		take := two_back + value
		current := if take > one_back { take } else { one_back }
		two_back = one_back
		one_back = current
	}
	return one_back
}
