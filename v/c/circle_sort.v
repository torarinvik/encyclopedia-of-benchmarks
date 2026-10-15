module circle_sort

fn circle_sort_range(mut values &i64, left_value usize, right_value usize) bool {
	if left_value >= right_value {
		return false
	}

	mut low := left_value
	mut high := right_value
	mut swapped := false
	for low < high {
		if unsafe { values[low] } > unsafe { values[high] } {
			temporary := unsafe { values[low] }
			unsafe {
				values[low] = values[high]
				values[high] = temporary
			}
			swapped = true
		}
		low++
		high--
	}
	if low == high && unsafe { values[low] } > unsafe { values[high + 1] } {
		temporary := unsafe { values[low] }
		unsafe {
			values[low] = values[high + 1]
			values[high + 1] = temporary
		}
		swapped = true
	}

	middle := left_value + (right_value - left_value) / 2
	left_swapped := circle_sort_range(mut values, left_value, middle)
	right_swapped := circle_sort_range(mut values, middle + 1, right_value)
	return swapped || left_swapped || right_swapped
}

@[export: 'circle_sort']
pub fn circle_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	for circle_sort_range(mut values, 0, length - 1) {
	}
}
