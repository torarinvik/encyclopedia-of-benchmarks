module fibonacci_sum

// Inclusive Fibonacci range sum for the shared unsigned pair ABI.
@[export: 'fibonacci_sum']
pub fn fibonacci_sum(start u64, end_value u64) i64 {
	if end_value > 90 || start > end_value {
		return -1
	}
	mut previous := i64(0)
	mut current := i64(1)
	mut lower := i64(0)
	mut lower_current := i64(1)
	lower_index := start + 1
	upper_index := end_value + 2
	mut i := u64(1)
	for i < upper_index {
		next := previous + current
		previous = current
		current = next
		if i < lower_index {
			lower_next := lower + lower_current
			lower = lower_current
			lower_current = lower_next
		}
		i++
	}
	return current - lower_current
}
