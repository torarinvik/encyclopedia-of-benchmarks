module square_root_binary_search

// Floor square root by binary search, with division avoiding square overflow.
@[export: 'square_root_binary_search']
pub fn square_root_binary_search(value i64) i64 {
	if value < 0 { return -1 }
	if value < 2 { return value }
	mut low := i64(1)
	mut high := value
	mut answer := i64(0)
	for low <= high {
		middle := low + (high - low) / 2
		if middle <= value / middle {
			answer = middle
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return answer
}
