package partition_sort

import "core:c"

partition_range :: proc(values: [^]i64, low, high: c.size_t) -> c.size_t {
	pivot := values[low]
	left, right := low, high
	for {
		for values[left] < pivot { left += 1 }
		for values[right] > pivot { right -= 1 }
		if left >= right do return right
		temporary := values[left]
		values[left] = values[right]
		values[right] = temporary
		left += 1
		right -= 1
	}
}

partition_sort_range :: proc(values: [^]i64, low, high: c.size_t) {
	if low < high {
		split := partition_range(values, low, high)
		partition_sort_range(values, low, split)
		partition_sort_range(values, split + 1, high)
	}
}

@(export)
partition_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		partition_sort_range(values, 0, length - 1)
	}
}
