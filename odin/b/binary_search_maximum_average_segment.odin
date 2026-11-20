package binary_search_maximum_average_segment

import "core:c"

MAX_N :: 32
MAX_INPUT :: 35
INVALID_RESULT :: i64(-1_000_001)

feasible :: proc(input: [^]i64, n, minimum_length: int, threshold: i64) -> bool {
	prefix: [33]i64
	prefix[0] = 0
	for index := 0; index < n; index += 1 {
		prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold
	}
	minimum_prefix := i64(9_223_372_036_854_775_807)
	for end := minimum_length; end <= n; end += 1 {
		eligible_start := end - minimum_length
		if prefix[eligible_start] < minimum_prefix do minimum_prefix = prefix[eligible_start]
		if prefix[end] >= minimum_prefix do return true
	}
	return false
}

@(export)
binary_search_maximum_average_segment :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return INVALID_RESULT
	n_value, minimum_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || minimum_value < 1 || minimum_value > n_value do return INVALID_RESULT
	n := int(n_value)
	if int(length) != n + 2 do return INVALID_RESULT
	for index := 0; index < n; index += 1 {
		if input[index + 2] < -1000 || input[index + 2] > 1000 do return INVALID_RESULT
	}

	low, high := i64(-1_000_000), i64(1_000_001)
	for high - low > 1 {
		middle := low + (high - low) / 2
		if feasible(input, n, int(minimum_value), middle) do low = middle else high = middle
	}
	return low
}
