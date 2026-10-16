module partition_sort

fn partition_range(mut values &i64, low usize, high usize) usize {
	pivot := unsafe { values[low] }
	mut left := low
	mut right := high
	for {
		for unsafe { values[left] < pivot } { left++ }
		for unsafe { values[right] > pivot } { right-- }
		if left >= right { return right }
		unsafe {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
		}
		left++
		right--
	}
	return right
}

fn partition_sort_range(mut values &i64, low usize, high usize) {
	if low < high {
		split := partition_range(mut values, low, high)
		partition_sort_range(mut values, low, split)
		partition_sort_range(mut values, split + 1, high)
	}
}

@[export: 'partition_sort']
pub fn partition_sort(mut values &i64, length usize) {
	if length > 1 {
		partition_sort_range(mut values, 0, length - 1)
	}
}
