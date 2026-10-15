package find_min_recursion

import "core:c"

MAX_LENGTH :: 256

find_min_range :: proc(values: [^]i64, low, high: int) -> i64 {
	if low == high do return values[low]
	middle := low + (high - low) / 2
	left := find_min_range(values, low, middle)
	right := find_min_range(values, middle + 1, high)
	return min(left, right)
}

@(export)
find_min_recursion :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return -1
	for i := 0; i < int(length); i += 1 {
		if values[i] < -2147483648 || values[i] > 2147483647 do return -1
	}
	return find_min_range(values, 0, int(length) - 1)
}
