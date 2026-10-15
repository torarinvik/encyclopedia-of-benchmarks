package quick_sort_3

import "core:c"

quick_sort_3_range :: proc "contextless" (values: [^]i64, low_value, high_value: c.size_t) {
	low := low_value
	high := high_value
	for high - low > 1 {
		pivot := values[high - 1]
		less := low
		scan := low
		greater := high
		for scan < greater {
			if values[scan] < pivot {
				temporary := values[less]
				values[less] = values[scan]
				values[scan] = temporary
				less += 1
				scan += 1
			} else if values[scan] > pivot {
				greater -= 1
				temporary := values[scan]
				values[scan] = values[greater]
				values[greater] = temporary
			} else {
				scan += 1
			}
		}
		if less - low < high - greater {
			quick_sort_3_range(values, low, less)
			low = greater
		} else {
			quick_sort_3_range(values, greater, high)
			high = less
		}
	}
}

@(export)
quick_sort_3 :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		quick_sort_3_range(values, 0, length)
	}
}
