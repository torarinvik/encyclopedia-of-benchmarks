package simple_binary_search

import "core:c"

simple_binary_search_range :: proc "contextless" (values: [^]i64, low, high: c.size_t, target: i64) -> i64 {
	if low >= high {
		return -1
	}

	middle := low + (high - low) / 2
	if values[middle] == target {
		return i64(middle)
	}
	if target < values[middle] {
		return simple_binary_search_range(values, low, middle, target)
	}
	return simple_binary_search_range(values, middle + 1, high, target)
}

@(export)
simple_binary_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	return simple_binary_search_range(values, 0, length, target)
}
