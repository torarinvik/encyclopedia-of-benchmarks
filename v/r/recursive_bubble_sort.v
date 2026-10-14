module recursive_bubble_sort

fn recursive_bubble_sort_range(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut index := usize(0)
	for index + 1 < length {
		if unsafe { values[index] } > unsafe { values[index + 1] } {
			temporary := unsafe { values[index] }
			unsafe {
				values[index] = values[index + 1]
				values[index + 1] = temporary
			}
		}
		index++
	}
	recursive_bubble_sort_range(mut values, length - 1)
}

@[export: 'recursive_bubble_sort']
pub fn recursive_bubble_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	recursive_bubble_sort_range(mut values, length)
}
