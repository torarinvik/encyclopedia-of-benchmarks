module bitonic_sort

fn bitonic_compare(mut values &i64, left usize, right usize, ascending bool) {
	unsafe {
		if (ascending && values[left] > values[right]) || (!ascending && values[left] < values[right]) {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
		}
	}
}

fn bitonic_merge(mut values &i64, low usize, length usize, ascending bool) {
	if length < 2 {
		return
	}
	half := length / 2
	for index := low; index < low + half; index++ {
		bitonic_compare(mut values, index, index + half, ascending)
	}
	bitonic_merge(mut values, low, half, ascending)
	bitonic_merge(mut values, low + half, half, ascending)
}

fn bitonic_sort_range(mut values &i64, low usize, length usize, ascending bool) {
	if length < 2 {
		return
	}
	half := length / 2
	bitonic_sort_range(mut values, low, half, true)
	bitonic_sort_range(mut values, low + half, half, false)
	bitonic_merge(mut values, low, length, ascending)
}

// Portable bitonic sorting network for power-of-two lengths.
@[export: 'bitonic_sort']
pub fn bitonic_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	bitonic_sort_range(mut values, 0, length, true)
}
