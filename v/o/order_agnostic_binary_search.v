// Binary search over a monotone sequence in either direction.
@[export: 'order_agnostic_binary_search']
pub fn order_agnostic_binary_search(values &i64, length usize) i64 {
	if length < 3 || length > 100001 { return -1 }
	target := unsafe { values[0] }
	count := unsafe { values[1] }
	if target < -2147483648 || target > 2147483647 || count < 1 || count > 99999 { return -1 }
	if length != usize(count) + 2 { return -1 }
	ascending := unsafe { values[2] < values[usize(count) + 1] }
	mut start := i64(0)
	mut right := count - 1
	for start <= right {
		middle := start + (right - start) / 2
		value := unsafe { values[usize(middle) + 2] }
		if value == target { return middle }
		if ascending {
			if value < target { start = middle + 1 } else { right = middle - 1 }
		} else {
			if value > target { start = middle + 1 } else { right = middle - 1 }
		}
	}
	return -1
}
