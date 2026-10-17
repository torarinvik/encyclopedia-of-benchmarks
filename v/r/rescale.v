module rescale

@[export: 'rescale']
pub fn rescale(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 260 { return -1 }
	max_value := input[0]
	new_max := input[1]
	draw_count := input[2]
	if max_value < 2 || max_value > 64 || new_max < 1 || new_max > 256 { return -1 }
	if draw_count < 1 || draw_count > 256 || length != usize(3 + draw_count) { return -1 }
	for index in 0 .. int(draw_count) {
		if input[3 + index] < 0 || input[3 + index] >= max_value { return -1 }
	}

	mut cursor := 0
	if new_max == max_value { return input[3] }

	if new_max < max_value {
		threshold := max_value - max_value % new_max
		for cursor < int(draw_count) {
			draw := input[3 + cursor]
			cursor++
			if draw < threshold { return draw % new_max }
		}
		return -1
	}

	mut result := i64(0)
	mut power := i64(1)
	for power < new_max {
		if cursor >= int(draw_count) { return -1 }
		result += power * input[3 + cursor]
		cursor++
		power *= max_value
	}
	if power == new_max { return result }

	threshold := power - power % new_max
	for result >= threshold {
		result = 0
		power = 1
		for power < new_max {
			if cursor >= int(draw_count) { return -1 }
			result += power * input[3 + cursor]
			cursor++
			power *= max_value
		}
	}
	return result % new_max
}
