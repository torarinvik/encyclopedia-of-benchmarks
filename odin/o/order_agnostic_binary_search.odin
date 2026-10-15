package order_agnostic_binary_search

import "core:c"

// Binary search over a monotone sequence in either direction.
@(export)
order_agnostic_binary_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 100001 do return -1
	target := values[0]
	count := values[1]
	if target < -2147483648 || target > 2147483647 || count < 1 || count > 99999 do return -1
	if length != c.size_t(count) + 2 do return -1
	ascending := values[2] < values[c.size_t(count) + 1]
	start := i64(0)
	right := count - 1
	for start <= right {
		middle := start + (right - start) / 2
		value := values[c.size_t(middle) + 2]
		if value == target do return middle
		if ascending {
			if value < target do start = middle + 1
			else do right = middle - 1
		} else {
			if value > target do start = middle + 1
			else do right = middle - 1
		}
	}
	return -1
}
