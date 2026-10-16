module naive_knapsack_solver

@[export: 'naive_knapsack_solver']
pub fn naive_knapsack_solver(values &i64, length usize) i64 {
	if length < 2 || length > 32 { return -1 }
	capacity := unsafe { values[0] }
	count := unsafe { values[1] }
	if capacity < 0 || capacity > 1_000_000 || count < 0 || count > 30 || length != usize(count) + 2 { return -1 }
	mut weight := i64(0)
	mut mask := i64(0)
	for i in 0 .. int(count) {
		item := unsafe { values[i + 2] }
		if item < 0 || item > 1_000_000 { return -1 }
		if weight + item <= capacity { weight += item; mask |= i64(1) << i }
	}
	return mask
}
