package double_linear_search

import "core:c"

MAX_ITEMS :: 100000
MAX_SAFE_INTEGER :: i64(9007199254740991)

// Two-ended linear search with source-compatible endpoint priority.
@(export)
double_linear_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 100002 do return -1
	target := values[0]
	count_value := values[1]
	if target < -MAX_SAFE_INTEGER || target > MAX_SAFE_INTEGER || count_value < 0 || count_value > MAX_ITEMS do return -1
	count := c.size_t(count_value)
	if length != count + 2 do return -1
	for index := c.size_t(0); index < count; index += 1 {
		if values[index + 2] < -MAX_SAFE_INTEGER || values[index + 2] > MAX_SAFE_INTEGER do return -1
	}
	start := c.size_t(0)
	right := count
	for start < right {
		if values[start + 2] == target do return i64(start)
		if values[right + 1] == target do return i64(right - 1)
		start += 1
		right -= 1
	}
	return -1
}
