package random_pivot_quick_sort

import "core:c"

random_pivot_quick_sort_next31 :: proc "contextless" (state: ^u64) -> u64 {
	state^ = (state^ * 48271) % 2147483647
	return state^
}

random_pivot_quick_sort_next :: proc "contextless" (state: ^u64) -> u64 {
	high := random_pivot_quick_sort_next31(state)
	low := random_pivot_quick_sort_next31(state)
	return high*2147483647 + low
}

random_pivot_quick_sort_partition :: proc "contextless" (values: [^]i64, low, high: c.size_t, state: ^u64) -> c.size_t {
	width := high - low
	pivot_index := low + c.size_t(random_pivot_quick_sort_next(state) % u64(width))
	pivot_value := values[pivot_index]
	pivot_slot := values[high-1]
	values[high-1] = pivot_value
	values[pivot_index] = pivot_slot
	boundary := low
	for scan := low; scan < high-1; scan += 1 {
		if values[scan] < pivot_value {
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
random_pivot_quick_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	stack_low: [128]c.size_t
	stack_high: [128]c.size_t
	stack_size := c.size_t(0)
	low := c.size_t(0)
	high := length
	random_state := u64(1)
	for {
		for high-low > 1 {
			pivot := random_pivot_quick_sort_partition(values, low, high, &random_state)
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
