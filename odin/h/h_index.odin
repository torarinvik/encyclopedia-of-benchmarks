package h_index

import "core:c"

// Find the greatest h for which at least h citations are >= h.
@(export)
h_index :: proc "c" (citations: [^]i64, length: c.size_t) -> i64 {
	if length > 5000 do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if citations[index] < 0 || citations[index] > 1000 do return -1
	}

	low := c.size_t(0)
	high := length
	if high > 1000 do high = 1000
	for low < high {
		middle := low + (high-low+1)/2
		qualifying := c.size_t(0)
		for index := c.size_t(0); index < length; index += 1 {
			if u64(citations[index]) >= u64(middle) {
				qualifying += 1
				if qualifying >= middle do break
			}
		}
		if qualifying >= middle {
			low = middle
		} else {
			high = middle - 1
		}
	}
	return i64(low)
}
