package single_non_duplicate

import "core:c"

MAX_VALUES :: 1025
INVALID_RESULT :: i64(-2_147_483_649)

// Binary search the pair alignment around the unique value.
@(export)
single_non_duplicate :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > c.size_t(MAX_VALUES) || length % 2 == 0 do return INVALID_RESULT
	left := 0
	right := int(length) - 1
	for left < right {
		middle := left + (right - left) / 2
		if middle % 2 == 0 {
			if values[middle] == values[middle + 1] do left = middle + 2
			else do right = middle
		} else {
			if values[middle] == values[middle - 1] do left = middle + 1
			else do right = middle - 1
		}
	}
	return values[left]
}
