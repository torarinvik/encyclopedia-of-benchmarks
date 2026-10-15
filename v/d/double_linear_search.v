const max_items = i64(100000)
const max_safe_integer = i64(9007199254740991)

// Two-ended linear search with source-compatible endpoint priority.
@[export: 'double_linear_search']
pub fn double_linear_search(values &i64, length usize) i64 {
	if length < 2 || length > 100002 { return -1 }
	target := unsafe { values[0] }
	count_value := unsafe { values[1] }
	if target < -max_safe_integer || target > max_safe_integer || count_value < 0 || count_value > max_items { return -1 }
	count := usize(count_value)
	if length != count + 2 { return -1 }
	for index := usize(0); index < count; index++ {
		value := unsafe { values[index + 2] }
		if value < -max_safe_integer || value > max_safe_integer { return -1 }
	}
	mut start := usize(0)
	mut right := count
	for start < right {
		if unsafe { values[start + 2] } == target { return i64(start) }
		if unsafe { values[right + 1] } == target { return i64(right - 1) }
		start++
		right--
	}
	return -1
}
