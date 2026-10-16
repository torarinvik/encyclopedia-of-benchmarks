module count_less_equal_in_sorted_array

@[export: 'count_less_equal_in_sorted_array']
pub fn count_less_equal_in_sorted_array(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 513 { return -1 }
	unsafe {
		key := input[0]
		if key < -2_147_483_648 || key > 2_147_483_647 { return -1 }
		for index in 1 .. length {
			value := input[index]
			if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
			if index > 1 && input[index - 1] > value { return -1 }
		}

		mut left := usize(1)
		mut right := length - 1
		mut count := usize(0)
		for left <= right {
			middle := left + (right - left) / 2
			if input[middle] > key { right = middle - 1 }
			else {
				count = middle
				left = middle + 1
			}
		}
		return i64(count)
	}
}
