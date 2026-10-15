module h_index

// Find the greatest h for which at least h citations are >= h.
@[export: 'h_index']
pub fn h_index(citations &i64, length usize) i64 {
	if length > 5000 { return -1 }
	for index in 0 .. length {
		value := unsafe { citations[index] }
		if value < 0 || value > 1000 { return -1 }
	}

	mut low := usize(0)
	mut high := length
	if high > 1000 { high = 1000 }
	for low < high {
		middle := low + (high - low + 1) / 2
		mut qualifying := usize(0)
		for index in 0 .. length {
			if u64(unsafe { citations[index] }) >= u64(middle) {
				qualifying++
				if qualifying >= middle { break }
			}
		}
		if qualifying >= middle { low = middle } else { high = middle - 1 }
	}
	return i64(low)
}
