package iterative_ternary_search

import "core:c"

@(export)
iterative_ternary_search :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -1
	target := packed[0]
	array_length := length - 1
	if array_length == 1 {
		if packed[1] == target do return 0
		return -1
	}
	left := c.size_t(0)
	right := array_length - 1
	for right > left {
		if packed[1 + left] == target do return i64(left)
		if packed[1 + right] == target do return i64(right)
		left_third := left + (right - left) / 3 + 1
		right_third := right - (right - left) / 3 - 1
		if packed[1 + left_third] <= target {
			left = left_third
		} else {
			right = right_third
		}
	}
	return -1
}
