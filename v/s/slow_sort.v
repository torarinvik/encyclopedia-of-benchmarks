module slow_sort

fn slow_sort_range(mut values &i64, first usize, last usize) {
	if first >= last { return }
	middle := first + (last - first) / 2
	slow_sort_range(mut values, first, middle)
	slow_sort_range(mut values, middle + 1, last)
	unsafe {
		if values[last] < values[middle] {
			temporary := values[last]
			values[last] = values[middle]
			values[middle] = temporary
		}
	}
	slow_sort_range(mut values, first, last - 1)
}

@[export: 'slow_sort']
pub fn slow_sort(mut values &i64, length usize) {
	if length > 1 { slow_sort_range(mut values, 0, length - 1) }
}
