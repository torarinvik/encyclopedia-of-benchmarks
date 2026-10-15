package circle_sort

import "core:c"

circle_sort_range :: proc "contextless" (values: [^]i64, left_value, right_value: c.size_t) -> bool {
	if left_value >= right_value {
		return false
	}

	low := left_value
	high := right_value
	swapped := false
	for low < high {
		if values[low] > values[high] {
			temporary := values[low]
			values[low] = values[high]
			values[high] = temporary
			swapped = true
		}
		low += 1
		high -= 1
	}
	if low == high && values[low] > values[high + 1] {
		temporary := values[low]
		values[low] = values[high + 1]
		values[high + 1] = temporary
		swapped = true
	}

	middle := left_value + (right_value-left_value)/2
	left_swapped := circle_sort_range(values, left_value, middle)
	right_swapped := circle_sort_range(values, middle+1, right_value)
	return swapped || left_swapped || right_swapped
}

@(export)
circle_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for circle_sort_range(values, 0, length-1) {
	}
}
