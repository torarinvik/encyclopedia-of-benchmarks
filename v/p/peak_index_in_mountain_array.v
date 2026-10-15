module peak_index_in_mountain_array

const max_array_length = 100000

// Find the peak of a strict mountain array with binary search.
@[export: 'peak_index_in_mountain_array']
pub fn peak_index_in_mountain_array(values &i64, length usize) i64 {
	if length < 3 || length > max_array_length { return -1 }
	unsafe {
		mut low := 0
		mut high := int(length) - 1
		for low < high {
			middle := low + (high - low) / 2
			if values[middle] < values[middle + 1] { low = middle + 1 }
			else { high = middle }
		}
		if low == 0 || low + 1 == int(length) { return -1 }
		return i64(low)
	}
}
