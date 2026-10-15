package first_bad_version

import "core:c"

// Find the first bad version with a lower-bound binary search.
@(export)
first_bad_version :: proc "c" (version_count, first_bad: u64) -> i64 {
	if version_count == 0 || version_count > 2147483647 || first_bad == 0 || first_bad > version_count do return -1

	low := u64(1)
	high := version_count
	for low < high {
		middle := low + (high-low)/2
		if middle >= first_bad {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return i64(low)
}
