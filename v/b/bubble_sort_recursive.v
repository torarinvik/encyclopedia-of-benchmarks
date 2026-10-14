module bubble_sort_recursive

fn bubble_sort_recursive_impl(mut values &i64, length usize) {
	if length <= 1 {
		return
	}
	mut swapped := false
	for index in usize(0) .. length - 1 {
		if unsafe { values[index] > values[index + 1] } {
			temporary := unsafe { values[index] }
			unsafe { values[index] = values[index + 1] }
			unsafe { values[index + 1] = temporary }
			swapped = true
		}
	}
	if swapped {
		bubble_sort_recursive_impl(mut values, length - 1)
	}
}

@[export: 'bubble_sort_recursive']
pub fn bubble_sort_recursive(mut values &i64, length usize) {
	if length <= 256 {
		bubble_sort_recursive_impl(mut values, length)
	}
}
