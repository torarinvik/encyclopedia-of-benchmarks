module knapsack_zero_one_tabulation

// Bottom-up 0/1 knapsack using one row and descending capacities.
@[export: 'knapsack_zero_one_tabulation']
pub fn knapsack_zero_one_tabulation(packed &i64, length usize) i64 {
	if length < 2 || length > 258 { return -1 }
	if unsafe { packed[0] } < 0 || unsafe { packed[0] } > 512 || unsafe { packed[1] } < 0 || unsafe { packed[1] } > 128 { return -1 }
	capacity := int(unsafe { packed[0] })
	item_count := int(unsafe { packed[1] })
	if length != usize(2 + 2 * item_count) { return -1 }
	for item in 0 .. item_count {
		weight := unsafe { packed[2 + 2 * item] }
		value := unsafe { packed[3 + 2 * item] }
		if weight < 1 || weight > 4096 || value < 0 || value > 1000000000 { return -1 }
	}

	mut dp := [513]i64{}
	width := capacity + 1
	steps := item_count * width
	for step := 0; step < steps; step++ {
		item := step / width
		current_capacity := capacity - step % width
		weight := int(unsafe { packed[2 + 2 * item] })
		value := unsafe { packed[3 + 2 * item] }
		if weight <= current_capacity {
			candidate := dp[current_capacity - weight] + value
			if candidate > dp[current_capacity] { dp[current_capacity] = candidate }
		}
	}
	return dp[capacity]
}
