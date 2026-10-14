module exponential_search

fn binary_search_range(values &i64, low_bound usize, high_bound usize, target i64) i64 {
	mut low := low_bound
	mut high := high_bound
	for low < high {
		middle := low + (high - low) / 2
		value := unsafe { values[middle] }
		if value == target {
			return i64(middle)
		}
		if value < target {
			low = middle + 1
		} else {
			high = middle
		}
	}
	return -1
}

// Exponential search in an ascending sequence for the shared benchmark contract.
@[export: 'exponential_search']
pub fn exponential_search(values &i64, length usize, target i64) i64 {
	if length == 0 {
		return -1
	}
	mut upper := usize(1)
	for upper < length && unsafe { values[upper] } <= target {
		if upper > length / 2 {
			upper = length
		} else {
			upper *= 2
		}
	}
	return binary_search_range(values, upper / 2, upper, target)
}
