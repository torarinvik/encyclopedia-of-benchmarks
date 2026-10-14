module sentinel_linear_search

// Sentinel linear search for the shared mutable-input benchmark contract.
@[export: 'sentinel_linear_search']
pub fn sentinel_linear_search(mut values &i64, length usize, target i64) i64 {
	if length == 0 {
		return -1
	}

	last_index := length - 1
	saved_last := unsafe { values[last_index] }
	if saved_last == target {
		return i64(last_index)
	}

	unsafe { values[last_index] = target }
	mut index := usize(0)
	for unsafe { values[index] } != target {
		index++
	}
	unsafe { values[last_index] = saved_last }

	if index == last_index {
		return -1
	}
	return i64(index)
}
