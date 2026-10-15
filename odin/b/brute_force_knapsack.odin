package brute_force_knapsack

import "core:c"

solve :: proc(packed: [^]i64, item_count: int, capacity: i64) -> i64 {
	if item_count == 0 || capacity == 0 do return 0
	weight := packed[2 + 2 * (item_count - 1)]
	value := packed[3 + 2 * (item_count - 1)]
	if weight > capacity do return solve(packed, item_count - 1, capacity)
	excluded := solve(packed, item_count - 1, capacity)
	included := value + solve(packed, item_count - 1, capacity - weight)
	if excluded > included do return excluded
	return included
}

@(export)
brute_force_knapsack :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 30 do return -1
	capacity := packed[0]
	count_value := packed[1]
	if capacity < 0 || capacity > 512 || count_value < 0 || count_value > 14 do return -1
	item_count := int(count_value)
	if length != c.size_t(2 + 2 * item_count) do return -1
	for item := 0; item < item_count; item += 1 {
		weight := packed[2 + 2 * item]
		value := packed[3 + 2 * item]
		if weight < 1 || weight > 4096 || value < 0 || value > 100000000 do return -1
	}
	return solve(packed, item_count, capacity)
}
