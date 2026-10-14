module binary_search

// Binary search in an ascending sequence for the shared benchmark contract.
@[export: 'binary_search']
pub fn binary_search(values &i64, length usize, target i64) i64 {
	mut low := usize(0)
	mut high := length
	for low < high {
		middle := low + (high - low) / 2
		value := unsafe { values[middle] }
		if value == target {
			return i64(middle)
		}
		if value < target {
			low = middle + 1
		} else {
			high = middle
		}
	}

	return -1
}
