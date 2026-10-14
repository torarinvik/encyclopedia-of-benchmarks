package stooge_sort

import "core:c"

stooge_sort_range :: proc(values: [^]i64, low, high: c.size_t) {
	length := high - low
	if length < 2 {
		return
	}
	if values[low] > values[high - 1] {
		temporary := values[low]
		values[low] = values[high - 1]
		values[high - 1] = temporary
	}
	if length > 2 {
		third := length / 3
		stooge_sort_range(values, low, high - third)
		stooge_sort_range(values, low + third, high)
		stooge_sort_range(values, low, high - third)
	}
}

@(export)
stooge_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		stooge_sort_range(values, 0, length)
	}
}
