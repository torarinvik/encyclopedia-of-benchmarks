package ruth_aaron_number_predicate

import "core:c"

MAX_N :: i64(100000)
MAX_PARSEABLE_LENGTH :: 2

factor_sum_counted :: proc "contextless" (value_arg: i64) -> i64 {
	value := value_arg
	total := i64(0)
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		for value % divisor == 0 {
			total += divisor
			value /= divisor
		}
	}
	if value > 1 do total += value
	return total
}

@(export)
ruth_aaron_number_predicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
	n := input[0]
	if factor_sum_counted(n) == factor_sum_counted(n + 1) do return 1
	return 0
}
