module stooge_sort

fn stooge_sort_range(mut values &i64, low usize, high usize) {
	length := high - low
	if length < 2 {
		return
	}
	if unsafe { values[low] > values[high - 1] } {
		unsafe {
			temporary := values[low]
			values[low] = values[high - 1]
			values[high - 1] = temporary
		}
	}
	if length > 2 {
		third := length / 3
		stooge_sort_range(mut values, low, high - third)
		stooge_sort_range(mut values, low + third, high)
		stooge_sort_range(mut values, low, high - third)
	}
}

// Stooge sort using half-open ranges.
@[export: 'stooge_sort']
pub fn stooge_sort(mut values &i64, length usize) {
	if length > 1 {
		stooge_sort_range(mut values, 0, length)
	}
}
