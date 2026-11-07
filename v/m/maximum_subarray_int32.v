module maximum_subarray_int32

@[export: 'maximum_subarray_int32']
pub fn maximum_subarray_int32(values &i64, length usize) i64 {
	if unsafe { values == nil } || length == 0 || length > 1024 { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -1000000 || value > 1000000 { return -1 }
	}
	mut current := unsafe { values[0] }
	mut best := current
	for index in 1 .. length {
		value := unsafe { values[index] }
		if current > 0 { current += value } else { current = value }
		if current > best { best = current }
	}
	return best
}
