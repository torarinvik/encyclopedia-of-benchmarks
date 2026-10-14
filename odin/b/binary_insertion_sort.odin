package binary_insertion_sort

import "core:c"

@(export)
binary_insertion_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	index := c.size_t(1)
	for index < length {
		key := values[index]
		low := c.size_t(0)
		high := index
		for low < high {
			middle := low + (high - low) / 2
			if values[middle] <= key {
				low = middle + 1
			} else {
				high = middle
			}
		}
		position := index
		for position > low {
			values[position] = values[position - 1]
			position -= 1
		}
		values[low] = key
		index += 1
	}
}
