package naive_knapsack_solver

import "core:c"

MAX_ITEMS :: 30
LIMIT :: i64 = 1_000_000

@(export)
naive_knapsack_solver :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_ITEMS + 2) do return -1
	capacity := values[0]
	count := values[1]
	if capacity < 0 || capacity > LIMIT || count < 0 || count > MAX_ITEMS || length != c.size_t(count) + 2 do return -1
	weight := i64(0)
	mask := i64(0)
	for i := 0; i < int(count); i += 1 {
		item := values[i + 2]
		if item < 0 || item > LIMIT do return -1
		if weight + item <= capacity { weight += item; mask |= i64(1) << i }
	}
	return mask
}
