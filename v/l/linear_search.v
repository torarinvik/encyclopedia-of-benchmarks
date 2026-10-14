module linear_search

// First-match linear search for the shared benchmark contract.
@[export: 'linear_search']
pub fn linear_search(values &i64, length usize, target i64) i64 {
	mut index := usize(0)
	for index < length {
		if unsafe { values[index] } == target {
			return i64(index)
		}
		index++
	}

	return -1
}
