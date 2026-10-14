module knapsack_recursive

fn solve(packed &i64, item_count int, capacity i64) i64 {
	if item_count == 0 || capacity == 0 { return 0 }
	offset := 2 + 2 * (item_count - 1)
	weight := unsafe { packed[offset] }
	value := unsafe { packed[offset + 1] }
	if weight <= capacity {
		take := value + solve(packed, item_count - 1, capacity - weight)
		skip := solve(packed, item_count - 1, capacity)
		if take > skip { return take }
		return skip
	}
	return solve(packed, item_count - 1, capacity)
}

@[export: 'knapsack_01_recursive_benchmark']
pub fn knapsack_01_recursive_benchmark(packed &i64, length usize) i64 {
	if length < 2 || length > 34 { return -1 }
	capacity := unsafe { packed[0] }
	item_count_value := unsafe { packed[1] }
	if capacity < 0 || capacity > 512 || item_count_value < 0 || item_count_value > 16 { return -1 }
	item_count := int(item_count_value)
	if length != usize(2 + 2 * item_count) { return -1 }
	for item in 0 .. item_count {
		offset := 2 + 2 * item
		weight := unsafe { packed[offset] }
		value := unsafe { packed[offset + 1] }
		if weight < 1 || weight > 4096 || value < 0 || value > 1000000000 { return -1 }
	}
	return solve(packed, item_count, capacity)
}
