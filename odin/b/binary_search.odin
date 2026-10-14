package binary_search

import "core:c"

// Binary search in an ascending sequence for the shared benchmark contract.
@(export)
binary_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	low := c.size_t(0)
	high := length
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
