package ways_to_split_array

import "core:c"

MAX_LENGTH :: 100_000
MAX_VALUE :: i64(100_000)

// Count positions where the prefix sum is at least the remaining suffix sum.
@(export)
ways_to_split_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > MAX_LENGTH do return -1
	n := int(length)
	total_sum := i64(0)
	for index := 0; index < n; index += 1 {
		if values[index] < -MAX_VALUE || values[index] > MAX_VALUE do return -1
		total_sum += values[index]
	}
	prefix_sum := i64(0)
	ways := i64(0)
	for index := 0; index < n - 1; index += 1 {
		prefix_sum += values[index]
		if prefix_sum >= total_sum - prefix_sum do ways += 1
	}
	return ways
}
