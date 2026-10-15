module single_non_duplicate

const max_values = 1025

// Binary search the pair alignment around the unique value.
@[export: 'single_non_duplicate']
pub fn single_non_duplicate(values &i64, length usize) i64 {
	if length == 0 || length > max_values || length % 2 == 0 { return -2147483649 }
	mut left := 0
	mut right := int(length) - 1
	for left < right {
		middle := left + (right - left) / 2
		if middle % 2 == 0 {
			if unsafe { values[middle] == values[middle + 1] } { left = middle + 2 }
			else { right = middle }
		} else {
			if unsafe { values[middle] == values[middle - 1] } { left = middle + 1 }
			else { right = middle - 1 }
		}
	}
	return unsafe { values[left] }
}
