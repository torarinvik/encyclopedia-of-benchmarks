package sentinel_linear_search

import "core:c"

// Sentinel linear search for the shared mutable-input benchmark contract.
@(export)
sentinel_linear_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length == 0 {
		return -1
	}

	last_index := length - 1
	saved_last := values[last_index]
	if saved_last == target {
		return i64(last_index)
	}

	values[last_index] = target
	index := c.size_t(0)
	for values[index] != target {
		index += 1
	}
	values[last_index] = saved_last

	if index == last_index {
		return -1
	}
	return i64(index)
}
