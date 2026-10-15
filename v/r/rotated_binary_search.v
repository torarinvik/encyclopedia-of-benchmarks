module rotated_binary_search

@[export: 'rotated_binary_search']
pub fn rotated_binary_search(input &i64, length usize) i64 {
	if length < 2 || unsafe { input == nil } { return -2 }
	unsafe {
		if input[0] < 0 || input[0] > 256 { return -2 }
		n := int(input[0])
		if length != usize(n + 2) { return -2 }
		if n == 0 { return -1 }
		key := input[n + 1]
		if key < -2_147_483_648 || key > 2_147_483_647 { return -2 }
		mut drops := 0
		for i in 0 .. n {
			if input[i + 1] < -2_147_483_648 || input[i + 1] > 2_147_483_647 { return -2 }
			if i > 0 && input[i] > input[i + 1] { drops++ }
		}
		if drops > 1 || (drops == 1 && input[n] > input[1]) { return -2 }
		mut left := 0
		mut right := n - 1
		for left <= right {
			middle := left + (right - left) / 2
			mid_value := input[middle + 1]
			if key == mid_value { return i64(middle) }
			if input[left + 1] == mid_value && mid_value == input[right + 1] {
				left++
				if right == 0 { break }
				right--
				continue
			}
			if input[left + 1] <= mid_value {
				if input[left + 1] <= key && key < mid_value {
					if middle == 0 { break }
					right = middle - 1
				} else { left = middle + 1 }
			} else if mid_value < key && key <= input[right + 1] { left = middle + 1 }
			else { if middle == 0 { break }; right = middle - 1 }
		}
		return -1
	}
}
