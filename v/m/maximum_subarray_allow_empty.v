module maximum_subarray_allow_empty

@[export: 'maximum_subarray_allow_empty']
pub fn maximum_subarray_allow_empty(values &i64, length usize) i64 {
	if length > 1024 || (length > 0 && unsafe { values == nil }) { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	mut current := i64(0)
	mut best := i64(0)
	for index in 0 .. length {
		current += unsafe { values[index] }
		if current < 0 { current = 0 }
		if current > best { best = current }
	}
	return best
}
