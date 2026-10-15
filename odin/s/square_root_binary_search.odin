package square_root_binary_search

import "core:c"

// Floor square root by binary search, with division avoiding square overflow.
@(export)
square_root_binary_search :: proc "c" (value: i64) -> i64 {
	if value < 0 do return -1
	if value < 2 do return value
	low := i64(1)
	high := value
	answer := i64(0)
	for low <= high {
		middle := low + (high-low)/2
		if middle <= value/middle {
			answer = middle
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return answer
}
