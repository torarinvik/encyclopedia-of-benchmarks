package knapsack_zero_one_tabulation

import "core:c"

// Bottom-up 0/1 knapsack using one row and descending capacities.
@(export)
knapsack_zero_one_tabulation :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 258 do return -1
	if packed[0] < 0 || packed[0] > 512 || packed[1] < 0 || packed[1] > 128 do return -1
	capacity := int(packed[0])
	item_count := int(packed[1])
	if length != c.size_t(2 + 2 * item_count) do return -1
	for item := 0; item < item_count; item += 1 {
		weight := packed[2 + 2 * item]
		value := packed[3 + 2 * item]
		if weight < 1 || weight > 4096 || value < 0 || value > 1000000000 do return -1
	}

	dp: [513]i64 = {}
	width := capacity + 1
	steps := item_count * width
	for step := 0; step < steps; step += 1 {
		item := step / width
		current_capacity := capacity - step % width
		weight := int(packed[2 + 2 * item])
		value := packed[3 + 2 * item]
		if weight <= current_capacity {
			candidate := dp[current_capacity - weight] + value
			if candidate > dp[current_capacity] do dp[current_capacity] = candidate
		}
	}
	return dp[capacity]
}
