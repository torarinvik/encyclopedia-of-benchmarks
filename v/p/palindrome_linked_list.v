module palindrome_linked_list

// Compare the linked-list value sequence from both ends without mutation.
@[export: 'palindrome_linked_list']
pub fn palindrome_linked_list(values &i64, length usize) i64 {
	if length > 100000 { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 9 { return -1 }
	}

	mut left := usize(0)
	mut right := length
	for left < right {
		right--
		if unsafe { values[left] } != unsafe { values[right] } { return 0 }
		left++
	}
	return 1
}
