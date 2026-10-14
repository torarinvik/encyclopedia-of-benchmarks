module recursive_binary_search

fn recursive_binary_search_range(values &i64, low usize, high usize, target i64) i64 {
	if low >= high {
		return -1
	}

	middle := low + (high - low) / 2
	if unsafe { values[middle] } == target {
		return i64(middle)
	}
	if target < unsafe { values[middle] } {
		return recursive_binary_search_range(values, low, middle, target)
	}
	return recursive_binary_search_range(values, middle + 1, high, target)
}

@[export: 'recursive_binary_search']
pub fn recursive_binary_search(values &i64, length usize, target i64) i64 {
	return recursive_binary_search_range(values, 0, length, target)
}
