package minimum_squares_to_represent_a_number

import "core:c"

// Bottom-up minimum-square-count dynamic programming, bounded to 4096.
@(export)
minimum_squares_to_represent_a_number :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > 4096 do return -1
	if input == 0 do return 1

	answers: [4097]i64
	for index := 0; index <= int(input); index += 1 { answers[index] = -1 }
	answers[0] = 0
	for value := 1; value <= int(input); value += 1 {
		best := i64(9223372036854775807)
		for root := 1; root <= value / root; root += 1 {
			candidate := 1 + answers[value - root * root]
			if candidate < best do best = candidate
		}
		answers[value] = best
	}
	return answers[int(input)]
}
