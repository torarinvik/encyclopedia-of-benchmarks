module minimum_squares_to_represent_a_number

// Bottom-up minimum-square-count dynamic programming, bounded to 4096.
@[export: 'minimum_squares_to_represent_a_number']
pub fn minimum_squares_to_represent_a_number(input i64) i64 {
	if input < 0 || input > 4096 { return -1 }
	if input == 0 { return 1 }

	mut answers := [4097]i64{}
	for index in 0 .. int(input + 1) { answers[index] = -1 }
	answers[0] = 0
	for value in 1 .. int(input + 1) {
		mut best := i64(9223372036854775807)
		mut root := 1
		for root <= value / root {
			candidate := 1 + answers[value - root * root]
			if candidate < best { best = candidate }
			root++
		}
		answers[value] = best
	}
	return answers[int(input)]
}
