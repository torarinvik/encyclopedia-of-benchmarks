package rescale

@(export)
rescale :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 260 do return -1
	max_value := input[0]
	new_max := input[1]
	draw_count := input[2]
	if max_value < 2 || max_value > 64 || new_max < 1 || new_max > 256 do return -1
	if draw_count < 1 || draw_count > 256 || length != c.size_t(3 + draw_count) do return -1
	for i in 0..<int(draw_count) {
		if input[3 + i] < 0 || input[3 + i] >= max_value do return -1
	}

	cursor := 0
	if new_max == max_value do return input[3]

	if new_max < max_value {
		threshold := max_value - max_value % new_max
		for cursor < int(draw_count) {
			draw := input[3 + cursor]
			cursor += 1
			if draw < threshold do return draw % new_max
		}
		return -1
	}

	result := i64(0)
	power := i64(1)
	for power < new_max {
		if cursor >= int(draw_count) do return -1
		result += power * input[3 + cursor]
		cursor += 1
		power *= max_value
	}
	if power == new_max do return result

	threshold := power - power % new_max
	for result >= threshold {
		result = 0
		power = 1
		for power < new_max {
			if cursor >= int(draw_count) do return -1
			result += power * input[3 + cursor]
			cursor += 1
			power *= max_value
		}
	}
	return result % new_max
}
