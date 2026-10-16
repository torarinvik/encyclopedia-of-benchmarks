package maximum_circular_subarray

import "core:c"

INVALID_RESULT :: i64(-9_223_372_036_854_775_807) - 1

@(export)
maximum_circular_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > 64 do return INVALID_RESULT
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < -1_000_000 || values[index] > 1_000_000 do return INVALID_RESULT
	}

	total := values[0]
	current_max := values[0]
	max_so_far := values[0]
	current_min := values[0]
	min_so_far := values[0]
	for index := c.size_t(1); index < length; index += 1 {
		value := values[index]
		current_max = max(current_max + value, value)
		max_so_far = max(max_so_far, current_max)
		current_min = min(current_min + value, value)
	min_so_far = min(min_so_far, current_min)
		total += value
	}
	if min_so_far == total do return max_so_far
	return max(max_so_far, total - min_so_far)
}
