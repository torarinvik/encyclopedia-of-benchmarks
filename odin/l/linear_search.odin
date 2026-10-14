package linear_search

import "core:c"

// First-match linear search for the shared benchmark contract.
@(export)
linear_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] == target {
			return i64(index)
		}
	}

	return -1
}
