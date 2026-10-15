package minimum_average_difference

import "core:c"

MAX_LENGTH :: 100_000
MAX_VALUE :: i64(100_000)

// Return the earliest split with the smallest difference of integer averages.
@(export)
minimum_average_difference :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > MAX_LENGTH do return -1
	n := int(length)
	total_sum := i64(0)
	for index := 0; index < n; index += 1 {
		if values[index] < 0 || values[index] > MAX_VALUE do return -1
		total_sum += values[index]
	}
	prefix_sum := i64(0)
	best_difference := i64(9_223_372_036_854_775_807)
	best_index := 0
	for index := 0; index < n; index += 1 {
		prefix_sum += values[index]
		left_average := prefix_sum / i64(index + 1)
		suffix_length := n - index - 1
		right_average := i64(0)
		if suffix_length > 0 {
			right_average = (total_sum - prefix_sum) / i64(suffix_length)
		}
		difference := left_average - right_average
		if difference < 0 do difference = -difference
		if difference < best_difference {
			best_difference = difference
			best_index = index
		}
	}
	return i64(best_index)
}
