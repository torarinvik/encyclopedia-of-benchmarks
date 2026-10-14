module selection_sort_recursive

fn minimum_index(values &i64, start usize, end usize) usize {
	if start + 1 >= end {
		return start
	}
	minimum := minimum_index(values, start + 1, end)
	if unsafe { values[start] } < unsafe { values[minimum] } {
		return start
	}
	return minimum
}

fn selection_sort_range(mut values &i64, start usize, length usize) {
	if start + 1 >= length {
		return
	}
	minimum := minimum_index(values, start, length)
	if minimum != start {
		temporary := unsafe { values[start] }
		unsafe {
			values[start] = values[minimum]
			values[minimum] = temporary
		}
	}
	selection_sort_range(mut values, start + 1, length)
}

@[export: 'selection_sort_recursive']
pub fn selection_sort_recursive(mut values &i64, length usize) {
	selection_sort_range(mut values, 0, length)
}
