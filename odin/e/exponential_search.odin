package exponential_search

import "core:c"

binary_search_range :: proc(values: [^]i64, low_bound, high_bound: c.size_t, target: i64) -> i64 {
	low := low_bound
	high := high_bound
	for low < high {
		middle := low + (high - low) / 2
		value := values[middle]
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
@(export)
exponential_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length == 0 {
		return -1
	}
	upper := c.size_t(1)
	for upper < length && values[upper] <= target {
		if upper > length / 2 {
			upper = length
		} else {
			upper *= 2
		}
	}
	return binary_search_range(values, upper / 2, upper, target)
}
