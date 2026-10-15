module simple_binary_search

fn simple_binary_search_range(values &i64, low usize, high usize, target i64) i64 {
	if low >= high {
		return 0
	}

	middle := low + (high - low) / 2
	if unsafe { values[middle] } == target {
		return 1
	}
	if target < unsafe { values[middle] } {
		return simple_binary_search_range(values, low, middle, target)
	}
	return simple_binary_search_range(values, middle + 1, high, target)
}

@[export: 'simple_binary_search']
pub fn simple_binary_search(values &i64, length usize, target i64) i64 {
	return simple_binary_search_range(values, 0, length, target)
}
