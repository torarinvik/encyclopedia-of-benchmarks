module brute_force_knapsack

fn solve(packed &i64, item_count int, capacity i64) i64 {
	if item_count == 0 || capacity == 0 { return 0 }
	unsafe {
		weight := packed[2 + 2 * (item_count - 1)]
		value := packed[3 + 2 * (item_count - 1)]
		if weight > capacity { return solve(packed, item_count - 1, capacity) }
		excluded := solve(packed, item_count - 1, capacity)
		included := value + solve(packed, item_count - 1, capacity - weight)
		if excluded > included { return excluded }
		return included
	}
}

@[export: 'brute_force_knapsack']
pub fn brute_force_knapsack(packed &i64, length usize) i64 {
	if length < 2 || length > 30 || unsafe { packed == nil } { return -1 }
	unsafe {
		capacity := packed[0]
		count_value := packed[1]
		if capacity < 0 || capacity > 512 || count_value < 0 || count_value > 14 { return -1 }
		item_count := int(count_value)
		if int(length) != 2 + 2 * item_count { return -1 }
		for item in 0 .. item_count {
			weight := packed[2 + 2 * item]
			value := packed[3 + 2 * item]
			if weight < 1 || weight > 4096 || value < 0 || value > 100000000 { return -1 }
		}
		return solve(packed, item_count, capacity)
	}
}
