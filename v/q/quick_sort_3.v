module quick_sort_3

fn quick_sort_3_range(mut values &i64, low_value usize, high_value usize) {
	mut low := low_value
	mut high := high_value
	unsafe {
		for high - low > 1 {
			pivot := values[high - 1]
			mut less := low
			mut scan := low
			mut greater := high
			for scan < greater {
				if values[scan] < pivot {
					temporary := values[less]
					values[less] = values[scan]
					values[scan] = temporary
					less++
					scan++
				} else if values[scan] > pivot {
					greater--
					temporary := values[scan]
					values[scan] = values[greater]
					values[greater] = temporary
				} else {
					scan++
				}
			}
			if less - low < high - greater {
				quick_sort_3_range(mut values, low, less)
				low = greater
			} else {
				quick_sort_3_range(mut values, greater, high)
				high = less
			}
		}
	}
}

@[export: 'quick_sort_3']
pub fn quick_sort_3(mut values &i64, length usize) {
	if length > 1 {
		quick_sort_3_range(mut values, 0, length)
	}
}
