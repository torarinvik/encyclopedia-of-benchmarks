package quick_sort

import "core:c"

partition :: proc(values: [^]i64, low, high: c.size_t) -> c.size_t {
	pivot := values[high - 1]
	boundary := low
	for scan := low; scan < high - 1; scan += 1 {
		if values[scan] <= pivot {
			temporary := values[boundary]
			values[boundary] = values[scan]
			values[scan] = temporary
			boundary += 1
		}
	}
	temporary := values[boundary]
	values[boundary] = values[high - 1]
	values[high - 1] = temporary
	return boundary
}

quick_sort_range :: proc(values: [^]i64, low_value, high_value: c.size_t) {
	low := low_value
	high := high_value
	for high - low > 1 {
		pivot := partition(values, low, high)
		right_start := pivot + 1
		if pivot - low < high - right_start {
			quick_sort_range(values, low, pivot)
			low = right_start
		} else {
			quick_sort_range(values, right_start, high)
			high = pivot
		}
	}
}

@(export)
quick_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		quick_sort_range(values, 0, length)
	}
}
