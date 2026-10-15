package quick_sort_iterative

import "core:c"

quick_sort_iterative_partition :: proc "contextless" (values: [^]i64, low, high: c.size_t) -> c.size_t {
	pivot := values[high-1]
	boundary := low
	for scan := low; scan < high-1; scan += 1 {
		if values[scan] <= pivot {
			temporary := values[boundary]
			values[boundary] = values[scan]
			values[scan] = temporary
			boundary += 1
		}
	}
	temporary := values[boundary]
	values[boundary] = values[high-1]
	values[high-1] = temporary
	return boundary
}

@(export)
quick_sort_iterative :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}

	stack_low: [128]c.size_t
	stack_high: [128]c.size_t
	stack_size := c.size_t(0)
	low := c.size_t(0)
	high := length
	for {
		for high-low > 1 {
			pivot := quick_sort_iterative_partition(values, low, high)
			left_size := pivot-low
			right_size := high-pivot-1
			if left_size < right_size {
				if right_size > 1 {
					stack_low[stack_size] = pivot + 1
					stack_high[stack_size] = high
					stack_size += 1
				}
				high = pivot
			} else {
				if left_size > 1 {
					stack_low[stack_size] = low
					stack_high[stack_size] = pivot
					stack_size += 1
				}
				low = pivot + 1
			}
		}
		if stack_size == 0 {
			break
		}
		stack_size -= 1
		low = stack_low[stack_size]
		high = stack_high[stack_size]
	}
}
