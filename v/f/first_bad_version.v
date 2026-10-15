module first_bad_version

// Find the first bad version with a lower-bound binary search.
@[export: 'first_bad_version']
pub fn first_bad_version(version_count u64, first_bad u64) i64 {
	if version_count == 0 || version_count > 2147483647 || first_bad == 0 || first_bad > version_count {
		return -1
	}
	mut low := u64(1)
	mut high := version_count
	for low < high {
		middle := low + (high - low) / 2
		if middle >= first_bad {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return i64(low)
}
