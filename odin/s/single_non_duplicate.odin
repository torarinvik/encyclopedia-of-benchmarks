package single_non_duplicate

import "core:c"

MAX_VALUES :: 1025
INVALID_RESULT :: i64(-2_147_483_649)

// Binary search the pair alignment around the unique value.
@(export)
single_non_duplicate :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_VALUES) || length % 2 == 0 do return INVALID_RESULT
	left := 0
	right := int(length) / 2
	for left < right {
		middle := left + (right - left) / 2
		if values[middle * 2] == values[middle * 2 + 1] do left = middle + 1
		else do right = middle
	}
	return values[left * 2]
}
