package problem65

@(export)
problem65 :: proc "c" (max_n: i64) -> i64 {
	if max_n < 1 || max_n > 100 do return -1
	previous: [256]i64
	current: [256]i64
	next: [256]i64
	previous[0] = 1
	current[0] = 2
	previous_length := i64(1)
	current_length := i64(1)
	for i := i64(2); i <= max_n; i += 1 {
		coefficient := i64(1)
		if i % 3 == 0 { coefficient = (2 * i) / 3 }
		carry := i64(0)
		for position := i64(0); position < current_length; position += 1 {
			old := i64(0)
			if position < previous_length { old = previous[position] }
			total := coefficient * current[position] + old + carry
			next[position] = total % 10
			carry = total / 10
		}
		next_length := current_length
		for carry != 0 {
			next[next_length] = carry % 10
			next_length += 1
			carry /= 10
		}
		for position := i64(0); position < current_length; position += 1 { previous[position] = current[position] }
		for position := i64(0); position < next_length; position += 1 { current[position] = next[position] }
		previous_length = current_length
		current_length = next_length
	}
	digit_sum := i64(0)
	for position := i64(0); position < current_length; position += 1 { digit_sum += current[position] }
	return digit_sum
}
