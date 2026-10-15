module minimum_size_subarray_sum

@[export: 'minimum_size_subarray_sum']
pub fn minimum_size_subarray_sum(packed &i64, length usize) i64 {
	if length < 2 { return -1 }
	target := unsafe { packed[0] }
	count := unsafe { packed[1] }
	if target < 1 || target > 1_000_000 || count < 0 || count > 256 || length != usize(count) + 2 {
		return -1
	}
	for index in 0 .. int(count) {
		value := unsafe { packed[index + 2] }
		if value < 1 || value > 1_000_000 { return -1 }
	}
	mut left := 0
	mut current_sum := i64(0)
	mut best := int(count) + 1
	for right in 0 .. int(count) {
		current_sum += unsafe { packed[right + 2] }
		for current_sum >= target {
			width := right - left + 1
			if width < best { best = width }
			current_sum -= unsafe { packed[left + 2] }
			left++
		}
	}
	if best <= int(count) { return i64(best) }
	return 0
}
