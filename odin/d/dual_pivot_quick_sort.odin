package dual_pivot_quick_sort

import "core:c"

dual_pivot_sort_range :: proc "contextless" (values: [^]i64, low_value, high_value: c.size_t) {
	low := low_value
	high := high_value
	for high - low > 2 {
		if values[low] > values[high - 1] {
			temporary := values[low]
			values[low] = values[high - 1]
			values[high - 1] = temporary
		}
		pivot1 := values[low]
		pivot2 := values[high - 1]
		less := low + 1
		scan := low + 1
		greater := high - 2
		for scan <= greater {
			if values[scan] < pivot1 {
				temporary := values[scan]
				values[scan] = values[less]
				values[less] = temporary
				less += 1
			} else if values[scan] >= pivot2 {
				for scan < greater && values[greater] > pivot2 {
					greater -= 1
				}
				temporary := values[scan]
				values[scan] = values[greater]
				values[greater] = temporary
				greater -= 1
				if values[scan] < pivot1 {
					second_temporary := values[scan]
					values[scan] = values[less]
					values[less] = second_temporary
					less += 1
				}
			}
			scan += 1
		}
		pivot1_index := less - 1
		pivot2_index := greater + 1
		first_temporary := values[low]
		values[low] = values[pivot1_index]
		values[pivot1_index] = first_temporary
		second_temporary := values[high - 1]
		values[high - 1] = values[pivot2_index]
		values[pivot2_index] = second_temporary
		left_size := pivot1_index - low
		middle_size := pivot2_index - pivot1_index - 1
		right_size := high - pivot2_index - 1
		if left_size >= middle_size && left_size >= right_size {
			dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index)
			dual_pivot_sort_range(values, pivot2_index + 1, high)
			high = pivot1_index
		} else if middle_size >= right_size {
			dual_pivot_sort_range(values, low, pivot1_index)
			dual_pivot_sort_range(values, pivot2_index + 1, high)
			low = pivot1_index + 1
			high = pivot2_index
		} else {
			dual_pivot_sort_range(values, low, pivot1_index)
			dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index)
			low = pivot2_index + 1
		}
	}
	if high - low == 2 && values[low] > values[low + 1] {
		temporary := values[low]
		values[low] = values[low + 1]
		values[low + 1] = temporary
	}
}

@(export)
dual_pivot_quick_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		dual_pivot_sort_range(values, 0, length)
	}
}
