module iterative_ternary_search

@[export: 'iterative_ternary_search']
pub fn iterative_ternary_search(packed &i64, length usize) i64 {
	if length < 2 {
		return -1
	}
	target := unsafe { packed[0] }
	array := unsafe { packed[1..length] }
	if array.len == 1 {
		return if array[0] == target { i64(0) } else { i64(-1) }
	}
	mut left := usize(0)
	mut right := array.len - 1
	for right > left {
		if array[left] == target {
			return i64(left)
		}
		if array[right] == target {
			return i64(right)
		}
		left_third := left + (right - left) / 3 + 1
		right_third := right - (right - left) / 3 - 1
		if array[left_third] <= target {
			left = left_third
		} else {
			right = right_third
		}
	}
	return -1
}
