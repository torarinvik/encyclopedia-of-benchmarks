module circle_sort

fn circle_pass(mut values &i64, low usize, high usize) bool {
	length := high - low
	if length < 2 {
		return false
	}
	mut swapped := false
	mut left := low
	mut right := high - 1
	for left < right {
		if unsafe { values[left] } > unsafe { values[right] } {
			temporary := unsafe { values[left] }
			unsafe {
				values[left] = values[right]
				values[right] = temporary
			}
			swapped = true
		}
		left++
		right--
	}
	if length % 2 != 0 && left == right && right + 1 < high && unsafe { values[right + 1] } < unsafe { values[right] } {
		temporary := unsafe { values[right] }
		unsafe {
			values[right] = values[right + 1]
			values[right + 1] = temporary
		}
		swapped = true
	}
	split := low + length / 2 + length % 2
	left_swapped := circle_pass(mut values, low, split)
	right_swapped := circle_pass(mut values, split, high)
	return swapped || left_swapped || right_swapped
}

@[export: 'circle_sort']
pub fn circle_sort(mut values &i64, length usize) {
	for length > 1 && circle_pass(mut values, 0, length) {}
}
