module binary_insertion_sort

// Stable binary insertion sort using an upper-bound search for each key.
@[export: 'binary_insertion_sort']
pub fn binary_insertion_sort(mut values &i64, length usize) {
	mut index := usize(1)
	for index < length {
		key := unsafe { values[index] }
		mut low := usize(0)
		mut high := index
		for low < high {
			middle := low + (high - low) / 2
			if unsafe { values[middle] <= key } {
				low = middle + 1
			} else {
				high = middle
			}
		}
		mut position := index
		for position > low {
			unsafe {
				values[position] = values[position - 1]
			}
			position--
		}
		unsafe {
			values[low] = key
		}
		index++
	}
}
