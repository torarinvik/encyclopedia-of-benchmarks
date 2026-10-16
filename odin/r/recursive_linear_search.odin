package recursive_linear_search

import "core:c"
import "core:runtime"

search_from_end :: proc(values: [^]i64, offset, count: c.size_t, target: i64) -> i64 {
	if count == 0 do return -1
	if values[offset + count - 1] == target do return i64(count - 1)
	return search_from_end(values, offset, count - 1, target)
}

@(export)
recursive_linear_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	context = runtime.default_context()
	if values == nil || length < 2 || length > 67 do return -1
	count_value, target := values[0], values[1]
	if count_value < 1 || count_value > 64 do return -1
	count := c.size_t(count_value)
	if length != count + 2 do return -1
	return search_from_end(values, 2, count, target)
}
