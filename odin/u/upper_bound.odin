package upper_bound

import "core:c"

upper_bound_range :: proc "contextless" (values: [^]i64, target: i64, left: i64, right: i64) -> i64 {
	if right <= left do return left
	middle := (left + right) / 2
	if target < values[middle] do return upper_bound_range(values, target, left, middle)
	return upper_bound_range(values, target, middle + 1, right)
}

@(export)
upper_bound :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length > 512 || target < -2147483648 || target > 2147483647 do return -1
	for i in 0..<length {
		if values[i] < -2147483648 || values[i] > 2147483647 do return -1
		if i > 0 && values[i - 1] > values[i] do return -1
	}
	return upper_bound_range(values, target, 0, i64(length) - 1)
}
