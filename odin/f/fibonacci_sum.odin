package fibonacci_sum

// Inclusive Fibonacci range sum for the shared unsigned pair ABI.
@(export)
fibonacci_sum :: proc "c" (start, end_value: u64) -> i64 {
	if end_value > 90 || start > end_value {
		return -1
	}
	previous: i64 = 0
	current: i64 = 1
	lower: i64 = 0
	lower_current: i64 = 1
	lower_index := start + 1
	upper_index := end_value + 2
	for i: u64 = 1; i < upper_index; i += 1 {
		next := previous + current
		previous = current
		current = next
		if i < lower_index {
			lower_next := lower + lower_current
			lower = lower_current
			lower_current = lower_next
		}
	}
	return current - lower_current
}
