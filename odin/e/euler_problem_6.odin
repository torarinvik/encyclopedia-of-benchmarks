package euler_problem_6

import "core:c"

MAX_N :: i64(100)
MAX_VALID_INPUT_LENGTH :: c.size_t(1)
MAX_INPUT_LENGTH :: c.size_t(2)

euler_problem_6 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < MAX_VALID_INPUT_LENGTH || length > MAX_INPUT_LENGTH do return -1
	if length != MAX_VALID_INPUT_LENGTH do return -1
	n := input[0]
	if n < 1 || n > MAX_N do return -1

	sum := i64(0)
	sum_of_squares := i64(0)
	for value := i64(1); value <= n; value += 1 {
		sum += value
		sum_of_squares += value * value
	}
	return sum * sum - sum_of_squares
}
