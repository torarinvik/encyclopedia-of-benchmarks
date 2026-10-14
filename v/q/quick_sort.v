module quick_sort

fn partition(mut values &i64, low usize, high usize) usize {
	pivot := unsafe { values[high - 1] }
	mut boundary := low
	for scan := low; scan < high - 1; scan++ {
		if unsafe { values[scan] <= pivot } {
			unsafe {
				temporary := values[boundary]
				values[boundary] = values[scan]
				values[scan] = temporary
			}
			boundary++
		}
	}
	unsafe {
		temporary := values[boundary]
		values[boundary] = values[high - 1]
		values[high - 1] = temporary
	}
	return boundary
}

fn quick_sort_range(mut values &i64, low_value usize, high_value usize) {
	mut low := low_value
	mut high := high_value
	for high - low > 1 {
		pivot := partition(mut values, low, high)
		right_start := pivot + 1
		if pivot - low < high - right_start {
			quick_sort_range(mut values, low, pivot)
			low = right_start
		} else {
			quick_sort_range(mut values, right_start, high)
			high = pivot
		}
	}
}

@[export: 'quick_sort']
pub fn quick_sort(mut values &i64, length usize) {
	if length > 1 {
		quick_sort_range(mut values, 0, length)
	}
}
