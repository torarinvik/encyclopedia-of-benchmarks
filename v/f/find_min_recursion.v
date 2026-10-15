module find_min_recursion

const max_length = 256

fn find_min_range(values &i64, low int, high int) i64 {
	if low == high { return unsafe { values[low] } }
	middle := low + (high - low) / 2
	left := find_min_range(values, low, middle)
	right := find_min_range(values, middle + 1, high)
	return if left <= right { left } else { right }
}

@[export: 'find_min_recursion']
pub fn find_min_recursion(values &i64, length usize) i64 {
	if unsafe { values == nil } || length == 0 || length > max_length { return -1 }
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	return find_min_range(values, 0, int(length) - 1)
}
